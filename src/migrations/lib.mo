import D "mo:base/Debug";

import MigrationTypes "./types";
import v0_0_1 "./v000_000_001";

module {
  let upgrades = [
    v0_0_1.upgrade,
    // do not forget to add your new migration upgrade method here
  ];

  func getMigrationId(state: MigrationTypes.State): Nat {
    return switch (state) {
      case (#v0_0_0(_)) 0;
      case (#v0_0_1(_)) 1;
      // do not forget to add your new migration id here
      // should be increased by 1 as it will be later used as an index to get upgrade/downgrade methods
    };
  };

  public func migrate(
    prevState: MigrationTypes.State, 
    nextState: MigrationTypes.State, 
    args: MigrationTypes.Args,
    caller: Principal
  ): MigrationTypes.State {

   
    var state = prevState;
     
    var migrationId = getMigrationId(prevState);
    let nextMigrationId = getMigrationId(nextState);

    while (migrationId < nextMigrationId) {
      let migrate =  upgrades[migrationId];
      migrationId := migrationId + 1;

      state := migrate(state, args, caller);
    };

    return state;
  };

  public let migration = {
    initialState = #v0_0_0(#data);
    //update your current state version
    currentStateVersion = #v0_0_1(#id);
    getMigrationId = getMigrationId;
    migrate = migrate;
  };

  public type Migration<T,A> = {
    initialState: T;
    currentStateVersion: T;
    getMigrationId: (T) -> Nat;
    migrate: (T,T,A,Principal) -> T;
  };

  public func runMigration<T,A>(stored : ?T, args: A, owner: Principal, migration : Migration<T,A>) : T {
    switch (stored) {
      case(null) (migration.migrate(migration.initialState, migration.currentStateVersion, args, owner) : T);
      case(?val) (migration.migrate(val, migration.currentStateVersion, args, owner) : T);
    };
  };
};