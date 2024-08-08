import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import List "mo:base/List";
import T "../type/types";

module {
    public class Vehicles() {
        Debug.print(debug_show ("Driver class invoked here...."));

        let vehiclesMap
             = HashMap.HashMap<Principal, T.Vehicle>(10, Principal.equal, Principal.hash);

        var unVerifiedVehicle = List.nil<T.Vehicle>();

        public func addUnVerifiedVehicle(vehicle: T.Vehicle) {
            Debug.print(debug_show ("Adding ride detail to backup...."));
            unVerifiedVehicle := List.push(vehicle, unVerifiedVehicle);
        };

        public func getVehicle(ownerId: Principal): (?T.Vehicle) {
            return vehiclesMap.get(ownerId);
        };

        public func addVehicle(ownerId: Principal, vehicle: T.Vehicle): () {
            Debug.print(debug_show ("Adding vehicle into map DS...."));
            vehiclesMap.put(ownerId, vehicle);
        }
    }
};