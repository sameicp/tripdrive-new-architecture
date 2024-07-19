import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Float "mo:base/Float";
import Nat "mo:base/Nat";
import List "mo:base/List";


module {

    public type RideID = {
        ride_id: Nat;
    };

    public type RequestID = {
        request_id: Nat;
    };

    public type UserType = {
        #Driver;
        #Passenger;
    };

    public type PaymentStatus = {
        #Paid;
        #NotPaid;
    };

    public type RideStatus = {
        #RideAccepted;
        #RideStarted;
        #RideCompleted;
        #RideCancelled;
    };

    public type RequestStatus = {
        #Accepted;
        #Pending;
        #Denied;
    };

    public type Position = {
        lat: Float;
        lng: Float;
    };

    public type Car = {
        name: Text;
        license_plate_number: Text;
        color: Text;
        car_model: Text;
        // image: Blob;
    };

    public type RideInformation = {
        ride_id: RideID;
        user_id: Principal;
        driver_id: Principal;
        origin: Position;
        destination: Position;
        var payment_status: PaymentStatus;
        var price: Float;
        var ride_status: RideStatus;
        date_of_ride: Nat;
    };

    public type RideInfoOutput = {
        ride_id: RideID;
        user_id: Principal;
        driver_id: Principal;
        origin: Position;
        destination: Position;
        payment_status: PaymentStatus;
        price: Float;
        ride_status: RideStatus;
        date_of_ride: Nat;
    };

    public type Profile = {
        username: Text;
        email: Text;
        phone_number: Text;
        bitcoin_address: Text;
        bitcoin_balance: Nat64;
    };

    public type User = {
        id: Principal;
        username: Text;
        email: Text;
        bitcoin_address: Text;
        phone_number: Text;
        var ride_history: List.List<RideID>;
    };
     
    public type Driver = {
        user: User;
        car: Car;
    };

    public type DriverOutput = {
        driver: Profile;
        car: Car;
    };

    public type RideRequestType = {
        request_id: RequestID;
        user_id: Principal;
        passenger_details: Profile;
        depature: Position;
        destination: Position;
        var status: RequestStatus;
        var price: Float;
    };

    public type RequestOutput = {
        request_id: RequestID;
        user_id: Principal;
        passenger_details: Profile;
        depature: Position;
        destination: Position;
        status: RequestStatus;
        price: Float;
    };

    public type PassengerInfor = {
        username: Text;
        phone_number: Text;
    };

    public type FullRequestInfo = {
        profile: Profile;
        request_id: RequestID;
        price: Float;
    };

    // creating types for inputs

    public type UserInput = {
        username: Text; 
        email: Text;
        phoneNumber: Text;
    };

    public type RequestInput = {
        depature: Position;
        destination: Position;
        price: Float;
    };
}