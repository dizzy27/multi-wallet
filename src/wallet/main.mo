import IC "./ic";
import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Blob "mo:base/Blob";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Manager "./manager";

// create a multi-sig wallet by this canister
actor {
  private let CYCLE_LIMIT = 2_000_000_000_000; //根据需要进行分配

  public query({caller}) func cycleBalance(): async Nat{
    Cycles.balance()
  };

  public shared({caller}) func wallet_receive(): async Nat {
    Cycles.accept(Cycles.available())
  };

  func size_of(texts: [Text]): Nat {
    var text_size = 0;
    for (_ in texts.vals()) {
      text_size += 1;
    };
    text_size
  };

  func init_members(members: [Text]): [Principal] {
    var principals = Buffer.Buffer<Principal>(size_of(members));
    for (member in members.vals()) {
      principals.add(Principal.fromText(member));
    };
    principals.toArray()
  };

  public shared({caller}) func create_manager(members_init: [Text], auth_threhold: Nat): async Principal {
    let ic: IC.Self = actor("aaaaa-aa"); //ledger actor的ID
    let members = init_members(members_init);
    assert(auth_threhold <= size_of(members_init));

    Cycles.add(CYCLE_LIMIT);
    let manager = await Manager.Manager(members, auth_threhold);
    let principal = Principal.fromActor(manager);

    await ic.update_settings({
      canister_id = principal;
      settings = {
        freezing_threshold = ?2592000;
        controllers = ?members;
        memory_allocation = ?0;
        compute_allocation = ?0;
      }
    });
    
    principal
  };

  // Only for test
  // type Operation = {
  //   #enable_auth;
  //   #disable_auth;
  //   #add_member: (Principal, Bool);
  //   #remove_member: Principal;
  //   #create_canister;
  //   #install_code: (Principal, Blob);
  //   #start_canister: Principal;
  //   #stop_canister: Principal;
  //   #delete_canister: Principal;
  // };
  // type Status = {
  //   #voting;
  //   #approved;
  //   #rejected;
  // };

  // // 实现M/N的多签提案 返回提案ID和可能的执行结果
  // public shared({caller}) func propose(proposal: Operation): async (Nat, Text) {
  //   (1 - 1, "")
  // };

  // // 实现M/N的多签执行 返回提案的状态和可能的执行结果
  // public shared({caller}) func vote(proposal_id: Nat, approve: Bool): async (Text, Text) {
  //   ("", "")
  // };

  // public query({caller}) func view_proposals(): async [(Nat, (Operation, Nat, Status))] {
  //   var proposals_buf = Buffer.Buffer<(Nat, (Operation, Nat, Status))>(0);
  //   proposals_buf.toArray()
  // };

  // public shared({caller}) func create_canister(pid: ?Nat) : async Principal {
  //   Principal.fromText("aaaaa-aa")
  // };

  // public shared({caller}) func install_code(
  //   wasm: Blob,
  //   canister: Principal,
  //   // mode: InstallMode
  //   pid: ?Nat
  // ) : async Text { 
    
  //   "Code installed for "
  // };

  // public shared({caller}) func start_canister(canister : Principal, pid: ?Nat) : async () {
    
  // };

  // public shared({caller}) func stop_canister(canister : Principal, pid: ?Nat) : async () {
    
  // };

  // public shared({caller}) func delete_canister(canister : Principal, pid: ?Nat) : async () {
    
  // };
};


// {
//   dependencies = [ "base" ],
//   compiler = None Text
// }


// let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.6.21-20220215/package-set.dhall
// let additions = [
//     ]
// in  upstream # additions
