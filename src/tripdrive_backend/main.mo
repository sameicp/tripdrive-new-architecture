import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import P "./entities/Passenger";
import V "./entities/Vehicles";
import TripdriveLogic "tripdrive_logic/TripdriveLogic";
import State "state/State";
import T "type/types";

actor class Tripdrive(owner: Principal) {

  Debug.print("Deploying Tripdrive on the Internet Computer...");

  let adminAddress: Principal = owner;
  Debug.print(debug_show (adminAddress));

  let vehicles: V.Vehicles = V.Vehicles();
  let passengers: P.Passengers = P.Passengers();
  let state: State.State = State.State();

  // TripdriveLogic.name("Initialising State here......");

  //-----------------------------------------------------//
  //---------------- Passenger public function ----------//
  //-----------------------------------------------------//

  public shared({caller}) func createAccount(passengerInfo: T.PassengerInput): async () {
    let passengerObj: T.Passenger = {
      identifier = caller;
      username = passengerInfo.username;
      email = passengerInfo.email;
      phoneNumber = passengerInfo.phoneNumber;
      var ownCar = #FALSE;
    };
    passengers.addPassengerToMap(caller, passengerObj);
  };

  public shared({caller}) func createRequest(inputRequest: T.RequestInput): async() {
    let request: T.Request = {
      requestId = 1;
      userId = caller;
      depature = inputRequest.depature;
      destination = inputRequest.destination;
      var status = #Pending;
      var price = inputRequest.price;
    };
    state.addRequest(caller, request);
  };

  public func getRequestStatus(principal: Principal): async(T.RequestStatus) {
    let optRequest = state.getRequest(principal);
    switch(optRequest) {
      case(?value) { 
        return value.status
       };
      case(null) {
        Debug.trap("Request not found");
      };
    };
  };

  public func getPassengerDetails(principal: Principal): async (T.PassengerInput) {
    let optPassenger: ?T.Passenger = passengers.getPassenger(principal);
    switch(optPassenger) {
      case(?value) { 
        return {
          username = value.username;
          email = value.email;
          phoneNumber = value.phoneNumber;
        }
       };
      case(null) { 
        Debug.trap("Passenger not found");
      };
    };
  };


  //---------------------------------------------------------------//
  //----------- Driver FUnctions ----------------------------------//
  //---------------------------------------------------------------//

  public shared({caller}) func registerCar(carDetails: T.VehicleInput): async (Text) {
    // first must check if the user have an account but skipping it for now
    let vehicle: T.Vehicle = {
      carName = carDetails.carName;
      carColor = carDetails.carColor;
      carModel = carDetails.carModel;
      carDescription = carDetails.carDescription;
      licensePlatenumber = carDetails.licensePlatenumber;
      carOwnerId = caller;
      carCapacity = carDetails.carCapacity;
      var carState = #Pending;
    };
    Debug.print(debug_show ("Adding vehicle to unverified vehicles"));
    vehicles.addUnVerifiedVehicle(vehicle);
    return "Your about to be verified"
  };

  public func getPassengerRequests(): async () {
    let requests = state.getListOfRequests();
  };


  public shared({caller}) func getPrincipal() : async Principal {
    caller
  };
}