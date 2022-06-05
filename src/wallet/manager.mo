import IC "./ic";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Blob "mo:base/Blob";
import RBT "mo:base/RBTree";
import Cycles "mo:base/ExperimentalCycles";
import SHA256 "mo:sha256/SHA256";
import Debug "mo:base/Debug";

// 多人钱包 Actor
actor class Manager(members_init: [Principal], auth_threshold: Nat) = self {
  private let CYCLE_LIMIT = 200_000_000_000;

  func size_of<T>(items: [T]): Nat {
    var item_size = 0;
    for (_ in items.vals()) {
      item_size += 1;
    };
    item_size
  };

  func includes(principals: [Principal], principal: Principal): Bool {
    for (p in principals.vals()) {
      if (Principal.toText(principal) == Principal.toText(p)) {
        return true
      };
    };
    false
  };

  func includes_proposal(ids: [Nat], id: Nat): Bool {
    for (i in ids.vals()) {
      if (i == id) {
        return true
      };
    };
    false
  };

  func check_auth(caller: Principal, proposal_id: ?Nat): Bool {
    if (not multi_auth) {
      assert(includes(members, caller));
      return true;
    };
    switch (proposal_id) {
      case (?proposal_id) {
        includes_proposal(to_be_excute_op.toArray(), proposal_id)
      };
      case (null) false
    }
  };

  // 该多人钱包所需要初始化的参数M，N以及最开始的小组成员
  private stable var N = size_of(members_init);
  private stable var M = auth_threshold;
  private stable var members = members_init;

  private stable var new_can_index: Nat = 0;
  private let cans = RBT.RBTree<Nat, Principal>(Nat.compare); // 存储创建的canister
  private stable var cans_text: [Text] = [];
  private stable var multi_auth = false;

  system func preupgrade() {
    if (new_can_index > 0) {
      var cans_buf = Buffer.Buffer<Text>(new_can_index);
      var i = 0;
      while (i < new_can_index) {
        let can = cans.get(i);
        switch (can) {
          case (?can) {
            cans_buf.add(Principal.toText(can));
          };
          case (null) { };
        };
        i += 1;
      };
      if (cans_buf.size() > 0) {
        cans_text := cans_buf.toArray();
      };
    };
  };

  system func postupgrade() {
    let cans_num = size_of(cans_text);
    if (cans_num > 0) {
      var i = 0;
      while (i < cans_num) {
        cans.put(new_can_index, Principal.fromText(cans_text[i]));
        new_can_index += 1;
        i += 1;
      };
    };
  };

  public query({caller}) func cycleBalance(): async Nat{
    Cycles.balance()
  };

  public shared({caller}) func wallet_receive(): async Nat {
    Cycles.accept(Cycles.available())
  };

  //创建被该多人钱包管理的canister
  public shared({caller}) func create_canister() : async IC.canister_id {
    assert(includes(members, caller));
    let settings = {
      freezing_threshold = null;
      controllers = ?[Principal.fromActor(self)];
      memory_allocation = null;
      compute_allocation = null;
    };
    let ic: IC.Self = actor("aaaaa-aa"); //ledger actor的ID

    Cycles.add(CYCLE_LIMIT);
    let result = await ic.create_canister({ settings = ?settings; });
    cans.put(new_can_index, result.canister_id);
    new_can_index += 1;
    result.canister_id
  };

  public shared({caller}) func add_member(member: Principal, add_threshold: Bool, pid: ?Nat): async Text {
    assert(not includes(members, member));
    assert(check_auth(caller, pid));

    var members_new = Buffer.Buffer<Principal>(N + 1);
    for (m in members.vals()) {
      members_new.add(m);
    };
    members_new.add(member);
    if (add_threshold) M += 1;

    members := members_new.toArray();
    "Success to add new member " # Principal.toText(member)
  };

  // type InstallMode = { #reinstall; #upgrade; #install };
  public shared({caller}) func install_code(
    wasm: Blob,
    canister: Principal,
    // mode: InstallMode
    pid: ?Nat
  ) : async Text { 
    assert(check_auth(caller, pid));

    let settings = {
      arg = [];  
      wasm_module = Blob.toArray(wasm);
      mode = #install; // mode;
      canister_id = canister;
    };
    let ic: IC.Self = actor("aaaaa-aa"); //ledger actor的ID
    await ic.install_code(settings);
    "Code installed for " # Principal.toText(canister)
  };

  public shared({caller}) func start_canister(canister : Principal, pid: ?Nat) : async () {
    assert(check_auth(caller, pid));

    let settings = { 
      canister_id = canister;
    };
    let ic: IC.Self = actor("aaaaa-aa"); //ledger actor的ID
    await ic.start_canister(settings)
  };

  public shared({caller}) func stop_canister(canister : Principal, pid: ?Nat) : async () {
    assert(check_auth(caller, pid));

    let settings = { 
      canister_id = canister;
    };
    let ic: IC.Self = actor("aaaaa-aa"); //ledger actor的ID
    await ic.stop_canister(settings)
  };

  public shared({caller}) func delete_canister(canister : Principal, pid: ?Nat) : async () {
    assert(check_auth(caller, pid));

    let settings = { 
      canister_id = canister;
    };
    let ic: IC.Self = actor("aaaaa-aa"); //ledger actor的ID
    await ic.delete_canister(settings)
  };

  // 调试测试专用 Hello
  type HelloCan = actor {
    greet: shared(Text) -> async Text;
  };

  public shared({caller}) func test_hello(canister: Text, name: Text): async Text {
    let hello: HelloCan = actor(canister);
    await hello.greet(name)
  };

  public query({caller}) func get_canisters(): async [Text] {
    var cans_buf = Buffer.Buffer<Text>(new_can_index);
    var i = 0;
    while (i < new_can_index) {
      let can = cans.get(i);
      switch (can) {
        case (?can) {
          let can_text = Principal.toText(can);
          cans_buf.add(can_text);
        };
        case (null) { assert(false) };
      };
      
      i += 1;
    };
    cans_buf.toArray()
  };

  public query({caller}) func get_members(): async [Principal] {
    members
  };

  type Operation = {
    #enable_auth;
    #disable_auth;
    #add_member: (Principal, Bool);
    #install_code: (Principal, Blob);
    #start_canister: Principal;
    #stop_canister: Principal;
    #delete_canister: Principal;
  };
  type Status = {
    #voting;
    #approved;
    #rejected;
  };

  private var new_proposal_index: Nat = 0;
  // <id, [(proposal, voters, approves, status)]>
  private let proposals = RBT.RBTree<Nat, (Operation, Buffer.Buffer<Principal>, Nat, Status)>(Nat.compare);
  private var to_be_excute_op = Buffer.Buffer<Nat>(0);
  private var to_be_install = RBT.RBTree<Nat, Blob>(Nat.compare);

  func excute_proposal(id: Nat, proposal: Operation): async () {
    switch (proposal) {
      case(#enable_auth) { multi_auth := true };
      case(#disable_auth) { multi_auth := false };
      case(#add_member params) { let _ = await add_member(params.0, params.1, ?id) };
      case(#install_code params) {
        let wasm = to_be_install.get(id);
        switch (wasm) {
          case (?wasm) {
            let _ = await install_code(wasm, params.0, ?id);
            to_be_install.delete(id);
          };
          case (null) { assert(false) };
        };
      };
      case(#start_canister principal) { await start_canister(principal, ?id) };
      case(#stop_canister principal) { await stop_canister(principal, ?id) };
      case(#delete_canister principal) { await delete_canister(principal, ?id) };
    };

    let approved = to_be_excute_op.toArray();
    to_be_excute_op.clear();
    for (pid in approved.vals()) {
      if (pid != id) to_be_excute_op.add(pid);
    };
  };

  // 实现M/N的多签提案
  public shared({caller}) func propose(proposal: Operation): async () {
    // Debug.print(Principal.toText(caller));
    assert(includes(members, caller));

    let voters = Buffer.Buffer<Principal>(1);
    voters.add(caller);

    var op: Operation = proposal;
    switch (proposal) {
      case(#install_code params) {
        let wasm = params.1;
        let hash = Blob.fromArray(SHA256.sha256(Blob.toArray(params.1)));
        op := #install_code((params.0, hash));
        to_be_install.put(new_proposal_index, wasm);
      };
      case _ { op := proposal };
    };
    
    if (M == 1) {
      proposals.put(new_proposal_index, (op, voters, 1, #approved));
      to_be_excute_op.add(new_proposal_index);
      await excute_proposal(new_proposal_index, op);
    } else {
      proposals.put(new_proposal_index, (op, voters, 1, #voting));
    };

    new_proposal_index += 1;
  };

  // 实现M/N的多签执行
  public shared({caller}) func vote(proposal_id: Nat, approve: Bool): async Text {
    // Debug.print(Principal.toText(caller));
    assert(includes(members, caller));

    let proposal = proposals.get(proposal_id);
    switch (proposal) {
      case (?proposal) {
        let voters = proposal.1;
        if (includes(voters.toArray(), caller)) return "Already voted";
        voters.add(caller);

        var approves = proposal.2;
        if (approve) approves += 1;

        if (voters.size() >= N or approves >= M) {
          if (approves >= M) {
            proposals.put(proposal_id, (proposal.0, voters, approves, #approved));
            to_be_excute_op.add(proposal_id);
            await excute_proposal(proposal_id, proposal.0);
            return "Proposal approved";
          }
          else {
            proposals.put(proposal_id, (proposal.0, voters, approves, #rejected));
            return "Proposal rejected";
          }
        }
        else {
          proposals.put(proposal_id, (proposal.0, voters, approves, #voting));
          return "Proposal voted";
        };
      };
      case (null) { "Error: No proposal found" };
    };
  };

  public query({caller}) func view_proposals(): async [(Nat, (Operation, Nat, Status))] {
    var proposals_buf = Buffer.Buffer<(Nat, (Operation, Nat, Status))>(new_proposal_index);
    var i = 0;
    while (i < new_proposal_index) {
      let proposal = proposals.get(i);
      switch (proposal) {
        case (?proposal) {
          proposals_buf.add((i, (proposal.0, proposal.2, proposal.3)));
        };
        case (null) { assert(false) };
      };
      i += 1;
    };
    proposals_buf.toArray()
  };
};


// {
//   dependencies = [ "base" ],
//   compiler = None Text
// }


// let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.6.18-20220107/package-set.dhall
// let additions = [
//     ]
// in  upstream # additions