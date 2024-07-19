import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import T "../type/types";

module {
    public class Passengers() {
        Debug.print(debug_show ("Passengers invoked....."));

        let passengerMap 
             = HashMap.HashMap<Principal, T.Passenger>(10, Principal.equal, Principal.hash);

        
        public func addPassengerToMap(identifier: Principal, passenger: T.Passenger): () {
            Debug.print(debug_show ("Adding passenger to Hashmap data structure"));
            passengerMap.put(identifier, passenger);
        };

        public func getPassenger(identifier: Principal): (?T.Passenger) {
            return passengerMap.get(identifier);
        };

        public func passengerOwnsCar(identifier: Principal): () {
            let optPassenger = getPassenger(identifier);
            let passenger = switch(optPassenger) {
                case(?value) { value };
                case(null) {Debug.trap("passenger is not found."); };
            };
            Debug.print(debug_show ("Updated: Passenger registered vehicle"));
            passenger.ownCar := #TRUE;
        }

    }
};