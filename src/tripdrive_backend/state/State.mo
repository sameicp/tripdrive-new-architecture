import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import List "mo:base/List";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Nat32 "mo:base/Nat32";
import T "../type/types";

module {

    public class State() {
        Debug.print("State invoked");
        let passengerToRequests 
             = HashMap.HashMap<Principal, T.Request>(10, Principal.equal, Principal.hash);
        let driverToRatings = HashMap.HashMap<Principal, Buffer.Buffer<Float>>(10, Principal.equal, Principal.hash);
        let passengerToRideId = HashMap.HashMap<Principal, Nat32>(10, Principal.equal, Principal.hash);
        let driverToRidesIds = HashMap.HashMap<Principal, Buffer.Buffer<Nat32>>(10, Principal.equal, Principal.hash);
        let rideIdToRideDetail = HashMap.HashMap<Nat32, T.RideDetail>(10, Nat32.equal, func(x){x});

        var requestsInfoStoreBackup = List.nil<T.Request>();
        var ridesInfoStoreBackup = List.nil<T.RideDetail>();
        var numberOfCompletedRides: Nat = 0;


        public func getNumberOfCompletedRides(): Nat {
            return numberOfCompletedRides;
        };


        //////////////////////////////
        // Passennger Request State //
        //////////////////////////////

        public func addRequest(passengerId: Principal, requestType: T.Request) {
            Debug.print(debug_show ("Adding requests...."));
            passengerToRequests.put(passengerId, requestType);
        };

        public func getRequest(passengerId: Principal): ?T.Request {
            Debug.print(debug_show ("Getting request for ", passengerId));
            return passengerToRequests.get(passengerId);
        };

        public func removeRequest(passengerId: Principal): ?T.Request {
            Debug.print(debug_show ("Removing the request..."));
            return passengerToRequests.remove(passengerId);
        };

        public func updateRequest(passengerId: Principal, newRequest: T.Request) {
            Debug.print(debug_show ("Updating with ", newRequest));
            let oldRequest = passengerToRequests.replace(passengerId, newRequest);
            Debug.print(debug_show ("Olde request ", oldRequest));
        };

        public func getListOfRequests(): [T.Request] {
            let requests: Iter.Iter<T.Request> = passengerToRequests.vals();
            return Iter.toArray(requests);
        };


        //////////////////////////
        // Driver Rating State ///
        //////////////////////////

        public func initialiseDriverRatingState(driverId: Principal) {
            let initialRatings = Buffer.Buffer<Float>(1); // empty buffer
            Debug.print(debug_show ("Adding initial rating to driver..."));
            driverToRatings.put(driverId, initialRatings);
        };

        public func addDriverRating(driverId: Principal, rating: Float) {
            // first get the Buffer stores in the hashmap
            let ratingsOpt = driverToRatings.get(driverId);
            switch(ratingsOpt) {
                case(?ratings) { 
                    ratings.add(rating);
                    let _ = driverToRatings.replace(driverId, ratings);
                    Debug.print(debug_show ("rating recorded successfully..."));
                 };
                case(null) { 
                    Debug.trap("Driver ratings are not found....");
                };
            };
        };

        public func getAverageRating(driverId: Principal): Float {
            Debug.print(debug_show ("Calculating driver average rating"));
            let ratings: [Float] = getRatings(driverId);
            let  baseValue: Float = 0;
            func add(a: Float, b: Float): Float {
                return a + b;
            };

            let totalRating: Float = Array.foldLeft<Float, Float>(ratings, baseValue, add);
            return totalRating;
        };

        public func getRatings(driverId: Principal): [Float] {
            Debug.print(debug_show ("Getting driver's ratings..."));
            let ratingsOpt = driverToRatings.get(driverId);
            switch(ratingsOpt) {
                case(?ratings) { 
                    Debug.print(debug_show ("Turning the ratings to array..."));
                    return Buffer.toArray(ratings);
                 };
                case(null) {
                    Debug.trap("Can not get drivers ratings...");
                 };
            };
        };

        public func getRatingsSize(driverId: Principal): Nat {
            let ratingsArray = getRatings(driverId);
            return Array.size(ratingsArray);
        };


        //////////////////////////
        // Accepted Rides State //
        //////////////////////////

        // Linking Passunger's Id with Ride if
        public func addRideIdForPassenger(passengerId: Principal, rideId: Nat32) {
            passengerToRideId.put(passengerId, rideId);
        };

        public func getRideIdForPassenger(passengerId: Principal): ?Nat32 {
            return passengerToRideId.get(passengerId);
        };

        public func clearRideIdWhenDone(passengerId: Principal) {
            passengerToRideId.delete(passengerId);
        };

        // Linking the Driver's Id with the rides ids
        public func attachRideIdToDriver(driverId: Principal, rideId: Nat32) {
            Debug.print(debug_show ("Extractings ride ids(if available)..."));
            let resultOpt = driverToRidesIds.get(driverId);
            switch(resultOpt) {
                case(?result) { 
                    Debug.print(debug_show ("Add a new element if buffer exists..."));
                    result.add(rideId);
                    let _ = driverToRidesIds.replace(driverId, result);
                 };
                case(null) {
                    Debug.print(debug_show ("Create new Buffer and add element..."));
                    let rideIds = Buffer.Buffer<Nat32>(0);
                    rideIds.add(rideId);
                    driverToRidesIds.put(driverId, rideIds);
                 };
            };
        };

        public func getRideIdsLinkedWithDriver(driverId: Principal): [Nat32] {
            Debug.print(debug_show ("Extracting the ride ids..."));
            let rideIdsOpt = driverToRidesIds.get(driverId);
            switch(rideIdsOpt) {
                case(?rideIds) { 
                    Debug.print(debug_show ("Extractions successful"));
                    return Buffer.toArray(rideIds);
                 };
                case(null) { 
                    Debug.trap("Can not extract the ride ids....");
                };
            };
        };

        public func removeRideIdFromDriver(driverId: Principal, rideId: Nat32) {
            Debug.print(debug_show ("Extracting the ride ids..."));
            let rideIdsOpt = driverToRidesIds.get(driverId);
            switch(rideIdsOpt) {
                case(?rideIds) { 
                    if (not Buffer.contains(rideIds, rideId, Nat32.equal)) {
                        Debug.trap("Ride id not linked to the driver...")
                    };
                    Debug.print(debug_show ("Removing the ride id ", rideId));
                    rideIds.filterEntries(func (index: Nat, value: Nat32): Bool {
                        return value == rideId;
                    });
                    Debug.print(debug_show ("Checking if driver ride ids is empty..."));
                    if (rideIds.size() == 0) {
                        Debug.print(debug_show ("Deleting driver records..."));
                        driverToRidesIds.delete(driverId);
                    }
                 };
                case(null) { 
                    Debug.trap("Can not extract the ride ids....");
                };
            };
        };


        ///////////////////////////////
        // Ride Object State //////////
        ///////////////////////////////

        //adding passenger's request to hashmap
        public func addRideDetail(rideId: Nat32, rideDetail: T.RideDetail) {
            Debug.print(debug_show ("Adding ride detail: ", rideDetail));
            rideIdToRideDetail.put(rideId, rideDetail);
        };

        public func getRideDetail(rideId: Nat32): ?T.RideDetail {
            Debug.print(debug_show ("Getting ride details for the id: " # Nat32.toText(rideId)));
            return rideIdToRideDetail.get(rideId);
        };

        public func removeRideDetail(rideId: Nat32): ?T.RideDetail {
            Debug.print(debug_show ("Removing ride with id: " # Nat32.toText(rideId)));
            return rideIdToRideDetail.remove(rideId);
        };

        public func updateRideDetail(rideId: Nat32, newRideDetail: T.RideDetail) {
            Debug.print(debug_show ("Updating ride id: " # Nat32.toText(rideId) # " with: ", newRideDetail));
            let oldRequest = rideIdToRideDetail.replace(rideId, newRideDetail);
            Debug.print(debug_show ("Older ride: ", oldRequest));
        };

        public func getListOfRideDetail(): [T.RideDetail] {
            Debug.print(debug_show ("Returns a list of all the ride details..."));
            let rides: Iter.Iter<T.RideDetail> = rideIdToRideDetail.vals();
            return Iter.toArray(rides);
        };


        //////////////////////////////////
        // Admin and System use Only /////
        //////////////////////////////////

        // requestInfoStoreBackup

        public func addRequestToBackUp(request: T.Request) {
            Debug.print(debug_show ("Adding a request to the backup...."));
            requestsInfoStoreBackup := List.push(request, requestsInfoStoreBackup);
        };

        public func clearRequestListFromBackup() {
            Debug.print(debug_show ("NB. Clearing requests backup storage..."));
            Debug.print(debug_show ("This action can only be done by the admin..."));
            requestsInfoStoreBackup := List.nil<T.Request>();
        };

        public func sizeOfRequestListFromBackup(): Nat {
            return List.size(requestsInfoStoreBackup);
        };

        // rideInfoStoreBackup

        public func addRideDetailListBackup(ride: T.RideDetail) {
            Debug.print(debug_show ("Adding ride detail to backup...."));
            ridesInfoStoreBackup := List.push(ride, ridesInfoStoreBackup);
        };

        public func clearRideDetailListBackup() {
            Debug.print(debug_show ("NB. Clearing ride details from backup storage...."));
            Debug.print(debug_show ("This action can only be done by the admin..."));
            ridesInfoStoreBackup := List.nil<T.RideDetail>();
        };

        public func sizeOfRideDetailListBackup(): Nat {
            return List.size(ridesInfoStoreBackup);
        }
    }
};