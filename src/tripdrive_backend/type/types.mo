import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Float "mo:base/Float";
import Nat "mo:base/Nat";
import List "mo:base/List";


module {

    public type OwnCar = {
        #TRUE;
        #FALSE;
    };

    public type Passenger = {
        identifier: Principal;
        username: Text;
        email: Text;
        phoneNumber: Text;
        var ownCar: OwnCar;
    };

    public type Vehicle = {
        carOwnerId: Principal;
        carName: Text;
        licensePlatenumber: Text;
        carColor: Text;
        carModel: Text;
        carCapacity: Nat;
        carDescription: Text;
        var carState: VehicleState;
    };

    public type VehicleState = {
        #Pending;
        #Accepted;
        #Banned;
    };

    public type Position = {
        lat: Float;
        lng: Float;
    };

     public type Request = {
        requestId: Nat32;
        userId: Principal;
        depature: Position;
        destination: Position;
        var status: RequestStatus;
        var price: Float;
    };

    public type RequestStatus = {
        #Accepted;
        #Pending;
        #Denied;
        #Cancelled;
    };

    public type RideDetail = {
        ride_id: Nat32;
        user_id: Principal;
        driver_id: Principal;
        origin: Position;
        destination: Position;
        var payment_status: PaymentStatus;
        var price: Float;
        var ride_status: RideStatus;
        date_of_ride: Nat;
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


    //-------------------------------------------------//
    //----------------- Input Values ------------------//
    //-------------------------------------------------//

    public type PassengerInput = {
        username: Text;
        email: Text;
        phoneNumber: Text;
    };

    public type RequestInput = {
        depature: Position;
        destination: Position;
        price: Float;
    };

    public type VehicleInput = {
        carName: Text;
        licensePlatenumber: Text;
        carColor: Text;
        carDescription: Text;
        carCapacity: Nat;
        carModel: Text;
    };



}