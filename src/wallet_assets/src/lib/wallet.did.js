export const idlFactory = ({ IDL }) => {
    return IDL.Service({
        'create_manager': IDL.Func(
            [IDL.Vec(IDL.Text), IDL.Nat],
            [IDL.Principal],
            [],
        ),
        'whoami': IDL.Func([], [IDL.Principal], ['query']),
    });
};
export const idlFactoryWallet = ({ IDL }) => {
    const Operation = IDL.Variant({
        'stop_canister': IDL.Principal,
        'add_member': IDL.Tuple(IDL.Principal, IDL.Bool),
        'enable_auth': IDL.Null,
        'start_canister': IDL.Principal,
        'delete_canister': IDL.Principal,
        'disable_auth': IDL.Null,
        'install_code': IDL.Tuple(IDL.Principal, IDL.Vec(IDL.Nat8)),
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
    });
};
export const init = ({ IDL }) => { return []; };