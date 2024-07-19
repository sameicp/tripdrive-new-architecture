import TrieMap "mo:base/TrieMap";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";
import List "mo:base/List";
import Debug "mo:base/Debug"; 
import Option "mo:base/Option";
import Array "mo:base/Array";
import Result "mo:base/Result";
import Error "mo:base/Error";
import Float "mo:base/Float";
import Int64 "mo:base/Int64";
import T "./type/types";

actor class TripDrive(admin: Principal) {

  let tripdrive_admin: Principal = admin;
  Debug.print(debug_show (Principal.toText(tripdrive_admin) # " is the admin"));
  
  // storage.
  let users_map 
    = TrieMap.TrieMap<Principal, T.User>(Principal.equal, Principal.hash);
  let drivers_map 
    = TrieMap.TrieMap<Principal, T.Driver>(Principal.equal, Principal.hash);

  // a record of the rides on the platform.
  stable var ride_information_storage = List.nil<T.RideInformation>();


  // List for a list of requests
  stable var pool_requests = List.nil<T.RideRequestType>();
  stable var request_id_counter = 0;
  stable var ride_id_counter = 0;
  stable let SATOSHI: Float = 100_000_000;

  let default_user: T.User = {
    id = Principal.fromText("2vxsx-fae");
    username = "";
    email = "";
    bitcoin_address = "";
    phone_number = "";
    var ride_history = List.nil<T.RideID>();
  };

  type Coordinates = {
    latitude: Float;
    longitude: Float;
  };

  type PaymentInfo = {
    destination_address: Text;
    amount_in_satoshi: Nat64;
  };

  type BitcoinActor = actor {
    get_p2pkh_address: Principal -> async Text;
    get_balance: Text -> async Nat64;
    send: PaymentInfo -> async Text;
  };

  type BitcoinAddress = Text;

  /////////////////////////
  /// PRIVATE METHODS   ///
  /////////////////////////

  func user_has_account(user_id: Principal): async Bool {
    if (Principal.isAnonymous(user_id)) { 
      Debug.trap("Annonymous id.")
    };

    // checking if the caller have already registered to the application
    let option_user: ?T.User = users_map.get(user_id);
    return Option.isSome(option_user);
  };

  func get_user_account(user_id: Principal): T.User {
    let option_user: ?T.User = users_map.get(user_id);
    let user: T.User = Option.get(option_user, default_user);
    return user;
  };

  func generate_request_id() : T.RequestID {
    let id = request_id_counter;
    request_id_counter += 1;
    return {
      request_id = id;
    };
  };

  func generate_ride_id() : T.RideID {
    let id = ride_id_counter;
    ride_id_counter += 1;
    return {
      ride_id = id;
    };
  };

  /// Define an internal helper function to retrieve requests by ID:
  func find_request(request_id : T.RequestID) : ?T.RideRequestType {
    let result: ?T.RideRequestType = 
      List.find<T.RideRequestType>(
        pool_requests, 
        func request = request.request_id == request_id);
    return result;
  };

  func extract_request(request_id : T.RequestID): T.RideRequestType {
    let request_option = find_request(request_id);
    return switch (request_option) {
      case null Debug.trap("Request id does not exist.");
      case (?request) request;
    };
  };

  func check_if_user_made_request(
    user_id: Principal, 
    request_id: T.RequestID): async() {
    // check if the user is the one who made the request
    let request: T.RideRequestType = extract_request(request_id);
    if (Principal.notEqual(user_id, request.user_id)) {
      Debug.trap("You are not the one who made the request");
    };

  };

  // get useful user information
  func user_info(user_id: Principal): async T.Profile {
    // get user information
    let option_user: ?T.User = users_map.get(user_id);
    let user: T.User = switch (option_user) {
      case null Debug.trap("User this ID " # Principal.toText(user_id) # " does not exist.");
      case (?user) user;
    };
    // let balance: Nat64 = await get_balance(user.bitcoin_address);
    let balance: Nat64 = 23;

    let user_profile: T.Profile = {
      username = user.username;
      email = user.email;
      phone_number = user.phone_number;
      bitcoin_address = user.bitcoin_address;
      bitcoin_balance = balance;
    };
    return user_profile;
  };

  // this function has to take in a list of requests and return passenger info nad the request id
  func passenger_details(requests_list: [T.RideRequestType]): async [T.FullRequestInfo] {
    let output: Buffer.Buffer<T.FullRequestInfo> = 
      Buffer.Buffer<T.FullRequestInfo>(10);

    for(request in requests_list.vals()) {
      let profile: T.Profile = await user_info(request.user_id);
      let updated_info: T.FullRequestInfo = {
        profile;
        request_id = request.request_id;
        price = request.price;
      };
      output.add(updated_info);
    };
    return Buffer.toArray<T.FullRequestInfo>(output);
  };

  func approve_ride(
      driver_id: Principal, 
      request: T.RideRequestType, 
      date_of_ride: Nat): async () {
    let ride_id = create_ride_object(request, date_of_ride, driver_id);
    add_ride_id_to_passenger(request.user_id, ride_id);
    await add_ride_to_driver(driver_id, ride_id);
  };

  func create_ride_object(
    request: T.RideRequestType, 
    date_of_ride: Nat, 
    driver_id: Principal
  ): T.RideID {
    
    let ride_info: T.RideInformation = {
      ride_id = generate_ride_id();
      user_id = request.user_id;
      driver_id;
      origin = request.depature;
      destination = request.destination;
      var payment_status = #NotPaid;
      var price = request.price;
      var ride_status = #RideAccepted;
      date_of_ride; 
    };

    ride_information_storage := List.push(ride_info, ride_information_storage);
    return ride_info.ride_id;
  };

  // function that adds the ride id to list of rides that the user has done
  // the function takes the ride id as an argument and the user id
  func add_ride_id_to_passenger(user_id: Principal, ride_id: T.RideID) {
    // first we check if the account exists
    let user: T.User = get_user_account(user_id);
    user.ride_history := List.push(ride_id, user.ride_history);
  };

  // add the ride information to the driver's history to keep statistics
  func add_ride_to_driver(driver_id: Principal, ride_id: T.RideID): async() {
    let option_driver: ?T.Driver = drivers_map.get(driver_id);
    let driver: T.Driver = switch (option_driver) {
      case null Debug.trap("User this ID " # Principal.toText(driver_id) # " does not exist.");
      case (?driver) driver;
    };

    driver.user.ride_history := List.push(ride_id, driver.user.ride_history);

  };

  func get_ride_option(ride_id: T.RideID): ?T.RideInformation {
    let ride_option: ?T.RideInformation = List.find<T.RideInformation>(
      ride_information_storage, 
      func ride = ride.ride_id ==ride_id
    );
    return ride_option;
  };

  func get_ride(ride_id: T.RideID): T.RideInformation {
    let ride_option: ?T.RideInformation = get_ride_option(ride_id);
    return switch (ride_option) {
      case null Debug.trap("Inexistent ride id");
      case (?ride) return ride;
    };
  };

  func driver_already_exists(id: Principal): async() {
    let option_driver: ?T.Driver = drivers_map.get(id);

    if (Option.isSome(option_driver)) {
      Debug.trap("Driver account already exists");
    };
  };

  func _create_request(request_id: T.RequestID, 
    user_id: Principal, 
    request_input: T.RequestInput, 
    passenger_details: T.Profile): T.RideRequestType {
    return {
      request_id;
      user_id;
      passenger_details;
      depature = request_input.depature;
      destination = request_input.destination;
      var status = #Pending;
      var price = request_input.price;
    };
  };

  func validate_driver(driver_id: Principal): async() {
    // check if the caller is the driver
    let option_driver: ?T.Driver = drivers_map.get(driver_id);
    if (Option.isNull(option_driver)) {
      Debug.trap("Driver not registered");
    };
  };

  func create_user(id: Principal, 
    user_input: T.UserInput, 
    user_address: Text): T.User {
    let ride_history = List.nil<T.RideID>();
    return {
      id;
      username = user_input.username;
      email = user_input.email;
      bitcoin_address = user_address;
      phone_number = user_input.phoneNumber;
      var ride_history;
    };
  };

  func create_driver_object(user: T.User, car: T.Car): T.Driver {
    return {
        user;
        car;
      };
  };

  func remove_request(request_id: T.RequestID) {
    pool_requests := 
        List.filter<T.RideRequestType>(
          pool_requests, 
          func request = request.request_id != request_id);
  };

  func check_principals(from_request: Principal, caller: Principal): async(){
    if(Principal.notEqual(from_request, caller)) {
      Debug.trap("not authorized to execute this function");
    };
  };

  func update_ride_status(ride: T.RideInformation) {
    ride.ride_status := #RideCompleted;
    ride.payment_status := #Paid;
  };

  func check_account(user_id:Principal): async() {
    if(await user_has_account(user_id)) {
      Debug.trap("The user is already registered")
    };
  };

  func check_user(user_id: Principal): async() {
    let is_user: Bool = await user_has_account(user_id);
    if(not is_user) {
      Debug.trap("Please start by creating an account as a user")
    };
  };

  func check_ride_info(ride_id: T.RideID): async () {
    let ride_option: ?T.RideInformation = get_ride_option(ride_id);
    if(Option.isNull(ride_option)) {
      Debug.trap("The information is not found.")
    };
  };

  func check_request(request_id: T.RequestID): async () {
    let request_option: ?T.RideRequestType = find_request(request_id);
    if(Option.isNull(request_option)) {
      Debug.trap("Request does not exist");
    };
  };

  let degreesToRadians = func (degrees: Float) : Float {
    return degrees * (Float.pi / 180.0);
  };
  
  func ride_information(id: Principal): T.RideInfoOutput {
    let user_account: T.User = get_user_account(id);
    let ride_ids: [T.RideID] = List.toArray(user_account.ride_history);
    let ride: T.RideInformation = get_ride(ride_ids[0]);
    let ride_result: T.RideInfoOutput = {
      ride_id = ride.ride_id;
      user_id = ride.user_id;
      driver_id = ride.driver_id;
      origin = ride.origin;
      destination = ride.destination;
      payment_status = ride.payment_status;
      price = ride.price;
      ride_status = ride.ride_status;
      date_of_ride = ride.date_of_ride;
    };
    return ride_result;
  };

  // that function has take to coordinates as input
  // the two coordinates which is lat and lng have to be converted into radians
  // calculates the distance of the coordinates
  func distance(first_pos: T.Position, second_pos: T.Position) : Float{
    let first_lat_rad: Float = degreesToRadians(first_pos.lat);
    let second_lat_rad: Float = degreesToRadians(second_pos.lat);
    let first_lng_rad: Float = degreesToRadians(first_pos.lng);
    let second_lng_rad: Float = degreesToRadians(second_pos.lng);

    // Havesine formula
    let dlat = second_lat_rad - first_lat_rad;
    let dlng = second_lng_rad - first_lng_rad;

    let a = Float.pow(Float.sin(dlat / 2.0), 2.0) 
              + Float.cos(first_lat_rad) * Float.cos(second_lat_rad) 
              * Float.pow(Float.sin(dlng / 2.0), 2.0);
    let c = 2 * Float.arcsin(Float.sqrt(a));
    // radius of the earth in km
    let r = 6371.0;
    // return the distance between two points
    return c * r;
  };

  ////////////////////
  // PUBLIC METHODS //
  ////////////////////

  ///////////////////////
  // Passenger Methods //
  ///////////////////////

  public shared({caller}) func create_user_acc(user_input: T.UserInput): async (Result.Result<Text, Text>) {
    try {
      if (
        user_input.username == "" or 
        user_input.phoneNumber == "" or 
        user_input.email == "") {
        return #err("Failed to create an account because of missing information.");
      };

      await check_account(caller);
      // let user_address: Text = await get_p2pkh_address(caller);
      let user_address: Text = "";
      // creating the user account
      let new_user: T.User = create_user(caller, user_input, user_address);
      users_map.put(caller, new_user);
      return #ok("User created successfuly");
    } catch e {
      return #err(Error.message(e))
    }
  };

  public shared({caller}) func create_request(request_input: T.RequestInput): async(Result.Result<T.RequestID, Text>) {
    try {
      // Validating the inputs so that the program does not allow to record empty input
      assert (request_input.depature != {});
      assert (request_input.destination != {});
      assert (request_input.price > 0.0);

      await check_user(caller);
      // generation the id of the request
      let request_id: T.RequestID = generate_request_id();
      // get basic infor about the passenger
      let passenger_details: T.Profile = await user_info(caller);
      // creating users request and add it to a list of requests
      let request: T.RideRequestType 
        = _create_request(request_id, caller, request_input, passenger_details);
      // adding the request into a pool of request
      pool_requests := List.push(request, pool_requests);
      return #ok(request_id);
    } catch e {
      return #err(Error.message(e));
    }
  };

  // the users can have the option to cancel the request
  public shared({caller}) func cancel_request(id: T.RequestID): async(Result.Result<Text, Text>) {
    try {
      // check if the user is the one who made the request
      await check_if_user_made_request(caller, id);
      remove_request(id);
      return #ok("request removed");
    } catch e {
      return #err(Error.message(e))
    }
  };

  // change the price on offer
  // am not sure if this works at all
  public shared({caller}) func change_price(
    request_id: T.RequestID, 
    new_price: Float): async(Result.Result<(), Text>) {
    try {
      await check_if_user_made_request(caller, request_id);
      await check_request(request_id);
      let request: T.RideRequestType = extract_request(request_id);
      request.price := new_price;
      return #ok()
    } catch e {
      return #err(Error.message(e));
    }
  };

  public shared({caller}) func get_request_status(request_id: T.RequestID): async(Result.Result<T.RequestStatus, Text>) {
    try {
      await check_if_user_made_request(caller, request_id);
      await check_request(request_id);
      let request: T.RideRequestType = extract_request(request_id);
      return #ok(request.status);
    } catch e {
      return #err(Error.message(e));
    };
  };

  public shared({caller}) func finished_ride(
    ride_id: T.RideID, 
    request_id: T.RequestID): async(Result.Result<(Text), Text>) {
    try {
      await check_ride_info(ride_id);
      let ride: T.RideInformation = get_ride(ride_id);
      await check_principals(ride.user_id, caller);
      let account_info =  await user_info(ride.driver_id);
      let payment_details: PaymentInfo = {
        destination_address = account_info.bitcoin_address;
        amount_in_satoshi = Int64.toNat64(Float.toInt64(ride.price * SATOSHI));
      };
      // let res: Text = await send(payment_details);
      let res: Text = "";
      remove_request(request_id);
      update_ride_status(ride);
      return #ok(res);
    } catch e {
      return #err(Error.message(e));
    }
  };
  
  public shared({caller}) func get_account(): async Result.Result<T.Profile, Text> {
    try{
      let account_info =  await user_info(caller);
      return #ok(account_info)
    } catch e {
      return #err(Error.message(e));
    }
  }; 

  public shared({caller}) func get_request(): async Result.Result<[T.RequestOutput], Text> {
    try {
      let requests_array: [T.RideRequestType] = List.toArray(pool_requests);
      let user_requests: [T.RideRequestType] 
        = Array.filter<T.RideRequestType>(
            requests_array, 
            func request = request.user_id == caller);
      let requests: [T.RequestOutput] = Array.map<T.RideRequestType, T.RequestOutput>(
        user_requests, 
        func request = {
          request_id = request.request_id;
          user_id = request.user_id;
          passenger_details = request.passenger_details;
          depature = request.depature;
          destination = request.destination;
          status = request.status;
          price = request.price;
        });
      return #ok(Array.take(requests, 1));
    } catch e {
      return #err(Error.message(e));
    }
  };

  public func passenger_info(user_id: Principal): async Result.Result<T.Profile, Text> {
    try{
      let account_info =  await user_info(user_id);
      return #ok(account_info)
    } catch e {
      return #err(Error.message(e));
    }
  };

  //////////////////////
  // Driver's Methods //
  //////////////////////

  // First the driver have to create an account as a normal user
  // get the driver basic infor from his user account
  // add some additonal about the driver like his car information
  // driver has to upload the images of his cars.
  public shared({caller}) func register_car(car: T.Car): async(Result.Result<(), Text>) {
    try {
      // check if the driver has already created an account
      await check_user(caller);
      await driver_already_exists(caller);
      // If the caller is not registered to the application he is not supposed to create an account
      let user: T.User = get_user_account(caller);
      // create an account if the account does not exist
      let new_driver: T.Driver = create_driver_object(user, car);
      // register the created account 
      drivers_map.put(caller, new_driver);
      return #ok()
    } catch e {
      return #err(Error.message(e))
    }
  };

  // logic after the driver has selected a passenger for the trip
  // this is the stage where we create a ride info object and add it to the list.
  public shared({caller}) func select_passenger(
    request_id: T.RequestID, 
    date_of_ride: Nat): async(Result.Result<(), Text>) {
    try {
      // get the request if it exist
      await check_request(request_id);
      let request: T.RideRequestType = extract_request(request_id);
      // update the request status to be accepted
      request.status := #Accepted;
      // approve the ride if the driver has selected the user
      await approve_ride(caller, request, date_of_ride);
      return #ok();
    } catch e {
      return #err(Error.message(e));
    }
  };
  
   public func get_requests(cur_pos: T.Position): async Result.Result<[T.RequestOutput], Text> {
    try {
      let requests_array: [T.RideRequestType] = List.toArray(pool_requests);
      let user_requests: [T.RideRequestType] 
        = Array.filter<T.RideRequestType>(
            requests_array, 
            func request 
              = (request.status == #Pending and distance(request.depature, cur_pos) <= 4.0));
      let requests: [T.RequestOutput] = Array.map<T.RideRequestType, T.RequestOutput>(
          user_requests, 
          func request = {
            request_id = request.request_id;
            user_id = request.user_id;
            passenger_details = request.passenger_details;
            depature = request.depature;
            destination = request.destination;
            status = request.status;
            price = request.price;
          });
      return #ok(requests);
    } catch e {
      return #err(Error.message(e));
    }
  };

  public shared({caller}) func passenger_onboarded(ride_id: T.RideID): async(Result.Result<(), Text>) {
   try { 
    await check_ride_info(ride_id);
    let ride: T.RideInformation = get_ride(ride_id);
    await check_principals(ride.driver_id, caller);
    ride.ride_status := #RideStarted;
    return #ok();
  } catch e {
    return #err(Error.message(e));
  }
  }; 

  public shared({caller}) func get_driver(): async Result.Result<Text, Text>{
    try {
      await validate_driver(caller);
      return #ok("cool");
    } catch e {
      return #err(Error.message(e))
    }
  };

  public func get_users_number(): async(Nat) {
    return users_map.size();
  };

  public func get_drivers_number(): async(Nat) {
    return drivers_map.size();
  };

  // record the lat and lng of the ride process
  public shared({caller}) func driver_rides(): async Result.Result<[T.RideInfoOutput], Text> {
    try{
      // get list of ride informantion ids
      let option_driver: ?T.Driver = drivers_map.get(caller);
      let driver: T.Driver = switch (option_driver) {
        case null Debug.trap("User this ID " # Principal.toText(caller) # " does not exist.");
        case (?driver) driver;
      }; 
      let ride_ids: [T.RideID] = List.toArray(driver.user.ride_history);   

      // scan through ride information using the ids
      let ride_information: [T.RideInformation] = List.toArray(ride_information_storage);
      var pending_rides: List.List<T.RideInformation> = List.nil<T.RideInformation>();
      for (ride_id in ride_ids.vals()) {
        for (ride_info in ride_information.vals()) {
          if (ride_id == ride_info.ride_id 
              and (ride_info.ride_status == #RideAccepted 
                    or ride_info.ride_status == #RideStarted)) {
            pending_rides := List.push(ride_info, pending_rides);
          };
        };
      };

      let array_pending_rides: [T.RideInformation] = List.toArray(pending_rides);
      let output_rides: [T.RideInfoOutput] = Array.map<T.RideInformation, T.RideInfoOutput>(
        array_pending_rides, 
        func ride = {
          ride_id = ride.ride_id;
          user_id = ride.user_id;
          driver_id = ride.driver_id;
          origin = ride.origin;
          destination = ride.destination;
          payment_status = ride.payment_status;
          price = ride.price;
          ride_status = ride.ride_status;
          date_of_ride = ride.date_of_ride;
        });

      // return the list of the ride information
      return #ok(output_rides);
    } catch e {
      return #err(Error.message(e));
    }
  }; 

  public shared({caller}) func get_ride_information(): async Result.Result<T.RideInfoOutput, Text> {
    try {
      let ride_result = ride_information(caller);
      return #ok(ride_result);
    } catch e {
      return #err(Error.message(e))
    }
  };

  public shared({caller}) func get_driver_info(): async Result.Result<T.DriverOutput, Text> {
    try {
      let ride_infor: T.RideInfoOutput = ride_information(caller);
      let driver_id: Principal = ride_infor.driver_id;
      // get the driver information
      let option_driver: ?T.Driver = drivers_map.get(driver_id);
      let driver: T.Driver = switch (option_driver) {
        case null Debug.trap("User this ID " # Principal.toText(driver_id) # " does not exist.");
        case (?driver) driver;
      };
      let driver_details: T.Profile = await user_info(driver_id);
      let output: T.DriverOutput = {
        driver = driver_details;
        car = driver.car;
      };
      return #ok(output);
    } catch e {
      return #err(Error.message(e));
    };
  };

};
