import Debug "mo:base/Debug";
import P "./entities/Passenger";
import V "./entities/Vehicles";
import TripdriveLogic "tripdrive_logic/TripdriveLogic";
import State "state/State";

actor class Tripdrive(owner: Principal) {

  Debug.print("Deploying Tripdrive on the Internet Computer...");

  let adminAddress: Principal = owner;
  Debug.print(debug_show (adminAddress));

  let drivers: V.Vehicles = V.Vehicles();
  let passengers: P.Passengers = P.Passengers();
  let state: State.State = State.State();

  // TripdriveLogic.name("Initialising State here......");

}