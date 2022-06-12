export const idlFactory = ({ IDL }) => {
    return IDL.Service({
        'create_manager': IDL.Func(
            [IDL.Vec(IDL.Text), IDL.Nat],
            [IDL.Principal],
            [],
        ),
    });
};
export const idlFactoryWallet = ({ IDL }) => {
    const Operation = IDL.Variant({
        'stop_canister': IDL.Principal,
        'add_member': IDL.Tuple(IDL.Principal, IDL.Bool),
        'enable_auth': IDL.Null,
        'start_canister': IDL.Principal,
        'remove_member': IDL.Principal,
        'delete_canister': IDL.Principal,
        'disable_auth': IDL.Null,
        'install_code': IDL.Tuple(IDL.Principal, IDL.Vec(IDL.Nat8)),
        'create_canister': IDL.Null,
    });
    const Status = IDL.Variant({
        'voting': IDL.Null,
        'approved': IDL.Null,
        'rejected': IDL.Null,
    });
    return IDL.Service({
        'get_members': IDL.Func(
            [],
            [IDL.Vec(IDL.Principal)],
            ['query'],
        ),
        'get_canisters': IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
        'view_proposals': IDL.Func(
            [],
            [IDL.Vec(IDL.Tuple(IDL.Nat, IDL.Tuple(Operation, IDL.Nat, Status)))],
            ['query'],
        ),
        'auth_enabled': IDL.Func([], [IDL.Bool], ['query']),
        'propose': IDL.Func([Operation], [IDL.Nat, IDL.Text], []),
        'vote': IDL.Func([IDL.Nat, IDL.Bool], [IDL.Text, IDL.Text], []),
        'create_canister': IDL.Func([IDL.Opt(IDL.Nat)], [IDL.Principal], []),
        'delete_canister': IDL.Func([IDL.Principal, IDL.Opt(IDL.Nat)], [], []),
        'install_code': IDL.Func(
            [IDL.Vec(IDL.Nat8), IDL.Principal, IDL.Opt(IDL.Nat)],
            [IDL.Text],
            [],
        ),
        'start_canister': IDL.Func([IDL.Principal, IDL.Opt(IDL.Nat)], [], []),
        'stop_canister': IDL.Func([IDL.Principal, IDL.Opt(IDL.Nat)], [], []),
    });
};
export const init = ({ IDL }) => { return []; };