import Debug "mo:base/Debug";
import Float "mo:base/Float";
import T "../type/types";

module {

    let degreesToRadians = func (degrees: Float) : Float {
        return degrees * (Float.pi / 180.0);
    };

    // that function has take to coordinates as input
    // the two coordinates which is lat and lng have to be converted into radians
    // calculates the distance of the coordinates
    public func distanceBetweenTwoPoints(positionA: T.Position, positionB: T.Position) : Float{
        let first_lat_rad: Float = degreesToRadians(positionA.lat);
        let second_lat_rad: Float = degreesToRadians(positionB.lat);
        let first_lng_rad: Float = degreesToRadians(positionA.lng);
        let second_lng_rad: Float = degreesToRadians(positionB.lng);

        // Havesine formula
        let dlat = second_lat_rad - first_lat_rad;
        let dlng = second_lng_rad - first_lng_rad;

        let a = Float.pow(Float.sin(dlat / 2.0), 2.0) 
                + Float.cos(first_lat_rad) * Float.cos(second_lat_rad) 
                * Float.pow(Float.sin(dlng / 2.0), 2.0);
        let c = 2 * Float.arcsin(Float.sqrt(a));
        // radius of the earth in km
        let r = 6371.0;
        return c * r;
    };
};