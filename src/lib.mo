import MigrationLib "./migrations";
import MigrationTypes "./migrations/types";

import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import D "mo:base/Debug";
import Error "mo:base/Error";
import Int "mo:base/Int";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Result "mo:base/Result";
import Text "mo:base/Text";


import BTree "mo:stableheapbtreemap/BTree";
import {URLEncoding} "mo:encoding/Base64";

import Service "service";
import CLService "cycleLedger";
import OrchestratorService "orchestratorService";
import ClassPlusLib "../../ClassPlus/src/";
import ICRC7 "mo:icrc7-mo";

module {

  let debug_channel= {
      announce = true;
  };

  public let Map =                  MigrationTypes.Current.Map;
  public let Set =                  MigrationTypes.Current.Set;
  public let BTree =                MigrationTypes.Current.BTree;
  public let Vector =               MigrationTypes.Current.Vector;

  public type State =               MigrationTypes.State;
  public type CurrentState =        MigrationTypes.Current.State;
  public type Environment =         MigrationTypes.Current.Environment;

  public type InitArgs =            MigrationTypes.Current.InitArgs;
  public type InitArgsList =            MigrationTypes.Current.InitArgsList;

  public type Stats =               MigrationTypes.Current.Stats;
  //public type FusionRPCService =          MigrationTypes.Current.FusionRPCService;


  public type RemoteContractPointer =        Service.RemoteContractPointer;
  public type RemoteOwner =                  Service.RemoteOwner;
  public type RequestRemoteOwnerRequest =     Service.RequestRemoteOwnerRequest;
  public type CastRequest =                   Service.CastRequest;
  public type CastResult =                    Service.CastResult;
  public type CastStatus =                    Service.CastStatus;
  public type CastStateShared =              Service.CastStateShared;
  public type CastCostRequest =               Service.CastCostRequest;
  public type RemoteTokenCost =               Service.RemoteTokenCost;
  public type CastState =                     MigrationTypes.Current.CastState;
  public type CastError =                     Service.CastError;
  public type ICRC16Map =                     Service.ICRC16Map;
  public type Account =                       Service.Account;
  public type RemoteOwnerResult =             Service.RemoteOwnerResult;
  public type RemoteOwnershipUpdateResult =   Service.RemoteOwnershipUpdateResult;
  public type Network =                       Service.Network;
  public type RemoteNFTPointer =              Service.RemoteNFTPointer;

  public type GetCallResult =                 OrchestratorService.GetCallResult;

  public func initialState() : State {#v0_0_0(#data)};

  public let networkHash = MigrationTypes.Current.networkHash;
  //public let fusionRPCHash = MigrationTypes.Current.fusionRPCHash;

  public let Migration = MigrationLib;


  public type ClassPlus = ClassPlusLib.ClassPlus<
    ICRC99, 
    State,
    InitArgs,
    Environment>;

  public func ClassPlusGetter(item: ?ClassPlus) : () -> ICRC99 {
    ClassPlusLib.ClassPlusGetter<ICRC99, State, InitArgs, Environment>(item);
  };

  public func Init<system>(config : {
      manager: ClassPlusLib.ClassPlusInitializationManager;
      initialState: State;
      args : ?InitArgsList;
      pullEnvironment : ?(() -> Environment);
      onInitialize: ?(ICRC99 -> async*());
      onStorageChange : ((State) ->())
    }) :()-> ICRC99{

      debug if(debug_channel.announce) D.print(debug_show(("ICRC99 Init", config.args)));

      ClassPlusLib.ClassPlus<system,
        ICRC99, 
        State,
        InitArgsList,
        Environment>({config with constructor = ICRC99}).get;
    };


  public class ICRC99(stored: ?State, caller: Principal, canisterId: Principal, args: ?InitArgsList, _environment: ?Environment, storageChanged: (State) -> ()){

    public let environment = switch(_environment){
      case(?val) val;
      case(null) D.trap("No Environment Set");
    };

    let lockAccount = {
      owner = canisterId;
      subaccount = ?Blob.fromArray([137, 230, 221, 144, 163, 86, 127, 219, 122, 226, 19, 221, 4, 253, 103, 28, 49, 143, 232, 219, 63, 101, 187, 221, 95, 4, 183, 14, 135, 163, 238, 247]);
    };

    

    public type RemoteContractPointer = Service.RemoteContractPointer;
    public type RemoteOwner = Service.RemoteOwner;

    let #v0_0_1(#data(state)) = Migration.runMigration<MigrationTypes.State, MigrationTypes.Args>(stored, null, caller, Migration.migration);

    storageChanged(#v0_0_1(#data(state)));


    let cycleLedger : CLService.Service = actor(Principal.toText(state.cycleSettings.cycleLedgerCanister));
    let orchestratorService : OrchestratorService.Service = actor(Principal.toText(state.orchestrator));

    public func get_state() : CurrentState {
      state;
    }; 

    public func get_environment() : Environment {
      environment;
    };


    public func get_stats() : Stats {
      return {
        nativeChain = state.nativeChain;
        service = state.service;
        orchestrator = state.orchestrator;
        native_chain = state.nativeChain;
        remoteOwnerMap = BTree.toArray(state.remoteOwnerMap);
        originalMinterMap = BTree.toArray(state.originalMinterMap);
        nextCastId = state.nextCastId;
        cycleSettings = {
          amountPerEthOwnerRequest = state.cycleSettings.amountPerEthOwnerRequest;
          amountPerSolanaOwnerRequest = state.cycleSettings.amountPerSolanaOwnerRequest;
          amountPerBitcoinOwnerRequest = state.cycleSettings.amountPerBitcoinOwnerRequest;
          amountPerICOwnerRequest = state.cycleSettings.amountPerICOwnerRequest;
          amountPerOtherOwnerRequest = state.cycleSettings.amountPerOtherOwnerRequest;
          amountBasePerOwnerRequest = state.cycleSettings.amountBasePerOwnerRequest;
          cycleLedgerCanister = state.cycleSettings.cycleLedgerCanister;
          amountPerETHCast = state.cycleSettings.amountPerETHCast;
        };
      };
    };

    public func native_chain(caller : Principal) : (RemoteContractPointer) {
      return state.nativeChain;
    };

    public func remote_owner_of(caller : Principal, requests: [Nat]) : [?RemoteOwner]{
      let results = Buffer.Buffer<?RemoteOwner>(1);

      if(requests.size() > environment.icrc7.get_state().ledger_info.max_query_batch_size){
        D.trap("batch size too large");
      };

      for(thisItem in requests.vals()){
        switch(BTree.get(state.remoteOwnerMap, Nat.compare, thisItem)){
          case(?owner) {
            results.add(?owner);
          };
          case(null){
            results.add(null);
          };
        };
      };

      return Buffer.toArray(results);
    };

    private func updateEthOwners(requests: [RemoteNFTPointer]) : async* ([?GetCallResult], Nat) {
      let totalCost = state.cycleSettings.amountPerEthOwnerRequest * requests.size();
      Cycles.add<system>(totalCost);
      try {
        let result = await orchestratorService.get_remote_owner(requests);
        let refunded = Cycles.refunded();
        return (result, totalCost - refunded);
      } catch (err) {
        let refunded = Cycles.refunded();
        return ([?#Err(#GenericError("Error getting remote owner " # Error.message(err)))],totalCost - refunded);
      };
    };

    public func request_remote_owner_status(caller: Principal, requests: [RequestRemoteOwnerRequest], account: ?Account) : async* [?RemoteOwnershipUpdateResult] {

      
      //check cycle balance?
      let totalNeeded = calcOwnerRequestCalc(requests);
      let balance = Cycles.available();

      var minimumBaseCost = state.cycleSettings.amountBasePerOwnerRequest * requests.size();
      var totalCharge = 0;

      if(balance < totalNeeded){
        let foundAccount = switch(account){
          case(?val){
            val;
          };
          case(null){
             return [?#Err(#InsufficientAllowance((0, totalNeeded)))];
          };
        };  
        //check remote allowance
        let foundAllowance = cycleLedger.icrc2_allowance({
          account = foundAccount;
          spender = {
            owner = state.orchestrator;
            subaccount = null;
          };
        });
        let foundBalance = cycleLedger.icrc1_balance_of(foundAccount);

        switch(await foundAllowance, await foundBalance){
          case(allowance, balance){
            if(allowance.allowance < totalNeeded){
              //todo charge base
              return [?#Err(#InsufficientAllowance((allowance.allowance, totalNeeded)))];
            };
            if(balance < totalNeeded){
              //todo charge base
              return [?#Err(#InsufficientBalance((balance, totalNeeded)))];
            };
          };
        };
      };

      let results = Buffer.Buffer<?RemoteOwnerResult>(requests.size());
      let groups = Map.new<Network,  Vector.Vector<(Nat,RemoteNFTPointer)>>();

      var index = 0;
      label proc for(thisItem in requests.vals()){
        let currentIndex = index;
        index += 1;
        let ?aNFT = environment.icrc7.get_nft(thisItem.remoteNFTPointer.tokenId) else {
          totalCharge += state.cycleSettings.amountBasePerOwnerRequest;
          results.put(currentIndex, ?#Err(#NotFound));
          continue proc;
        };

        let ?remoteOwner = BTree.get(state.remoteOwnerMap, Nat.compare, thisItem.remoteNFTPointer.tokenId) else {
          totalCharge += state.cycleSettings.amountBasePerOwnerRequest;
          results.put(currentIndex, ?#Err(#NotFound));
          continue proc;
        };

        switch(remoteOwner){
          case(#local(owner)){
            totalCharge += state.cycleSettings.amountBasePerOwnerRequest;
            results.add(?#Ok(#local(owner)));
          };
          case(#remote(details)){
            //need to ask orchestrator for update
            switch(details.contract.network){
              case(#Ethereum(val)){
                let aVec = switch(Map.get(groups, networkHash, #Ethereum(val))){
                  case(?vec){
                    vec;
                  };
                  case(null){
                    let vec : Vector.Vector<(Nat, RemoteNFTPointer)> = Vector.new<(Nat, RemoteNFTPointer)>();
                    ignore Map.put(groups, networkHash, #Ethereum(val) : Network, vec : Vector.Vector<(Nat, RemoteNFTPointer)>);
                    vec;
                  };
                };
                Vector.add(aVec, (currentIndex, thisItem.remoteNFTPointer));
                //results.add(?remoteOwner);
              };
              case(_){
                //todo: charge the total cost/base amount

                return [?#Err(#GenericError("nyi"))];
              };
            };
          };
        };

        let awaits = Buffer.Buffer<(Vector.Vector<(Nat, RemoteNFTPointer)>, async* ([?GetCallResult], Nat))>(Map.size(groups));

        //todo check that groups aren't too big

        label procAwaits for(thisEntry in Map.entries(groups)){
          let (network, vecs) = thisEntry;
          switch(network){
            case(#Ethereum(val)){
              awaits.add((vecs, updateEthOwners(Vector.toArray<RemoteNFTPointer>(Vector.map<(Nat, RemoteNFTPointer), RemoteNFTPointer>(vecs, func(x: (Nat, RemoteNFTPointer)){
                x.1;
              })))));
            };
            case(#Solana(val)){
              //todo: get rid of these traps and make sure you charge the base
              D.trap("nyi");
            };
            case(#Bitcoin(val)){
              D.trap("nyi");
            };
            case(#IC(val)){
              D.trap("nyi");
            };
            case(#Other(val)){
              D.trap("nyi");
            };
          };
        };

        label procResults for(thisAwait in awaits.vals()){
          let (vecs, result) = thisAwait;
          let (awaitResults, cost) = await* result;
          var procIndex = 0;
          for(thisResult in awaitResults.vals()){
            let currentIndex = procIndex;
            procIndex += 1;
            let (index, _) = Vector.get(vecs,procIndex);
            switch(thisResult){
              case(?#Ok(val)){
                //todo: check that the owner is ourself!
                let thisItem = requests.get(index);
                let remoteOwner = #remote({
                  contract = {
                    contract = thisItem.remoteNFTPointer.contract;
                    network = thisItem.remoteNFTPointer.network;
                  };
                  owner = val;
                  timestamp = Int.abs(Time.now());
                });
                ignore BTree.insert(state.remoteOwnerMap, Nat.compare, thisItem.remoteNFTPointer.tokenId, remoteOwner);
                results.put(index, ?#Ok(remoteOwner));
              };
              case(?#Err(val)){
                results.put(index, ?#Err(#GenericError("remote error" # debug_show(val))));
              };
              case(null){
                results.put(index, null);
              };
            };
          };
        };
      };

      return Buffer.toArray(results);
    };

    public func calcOwnerRequestCalc(items: [RequestRemoteOwnerRequest]) : Nat {
      var total = 0;
      for(thisItem in items.vals()){
        switch(thisItem.remoteNFTPointer.network){
          case(#Ethereum(val)){
            total += state.cycleSettings.amountPerEthOwnerRequest;
          };
          case(#Solana(val)){
            D.trap("nyi");
          };
          case(#Bitcoin(val)){
            D.trap("nyi");
          };
          case(#IC(val)){
            D.trap("nyi");
          };
          case(#Other(val)){
            D.trap("nyi");
          };
        };
      };
      total;
    };



    public func cast(caller: Principal, requests: [CastRequest], account: ?Account) : async* [?CastResult] {

      debug if(debug_channel.announce) D.print(debug_show("Cast Request: " # debug_show(requests)));
      //check cycle balance?
      let totalNeeded = calcCastCost(requests);
      var balance = Cycles.available();

      var minimumBaseCost = state.cycleSettings.amountBasePerOwnerRequest * requests.size();
      var totalCharge = 0;
      var procPending = false;

      debug if(debug_channel.announce) D.print(debug_show("Total Needed: " # debug_show(totalNeeded) # " Balance: " # debug_show(balance)));

      debug if(debug_channel.announce) D.print(debug_show("Minimum Base Cost: " # debug_show(minimumBaseCost)));

      debug if(debug_channel.announce) D.print(debug_show("Service: " # debug_show(state.service)));

      if(balance < totalNeeded and ?caller != state.service){
        debug if(debug_channel.announce) D.print(debug_show("Balance too low"));
        let foundAccount = switch(account){
          case(?val){
            val;
          };
          case(null){
             return [?#Err(#InsufficientAllowance((0, totalNeeded)))];
          };
        };  
        //check remote allowance
        let foundAllowance = cycleLedger.icrc2_allowance({
          account = foundAccount;
          spender = {
            owner = state.orchestrator;
            subaccount = null;
          };
        });
        let foundBalance = cycleLedger.icrc1_balance_of(foundAccount);

        switch(await foundAllowance, await foundBalance){
          case(allowance, foundBalance){
            if(allowance.allowance < totalNeeded){
              //todo charge base
              return [?#Err(#InsufficientAllowance((allowance.allowance, totalNeeded)))];
            };
            if(foundBalance < totalNeeded){
              //todo charge base
              return [?#Err(#InsufficientBalance((balance, totalNeeded)))];
            };
            balance := totalNeeded;
          };
        };
      };

      debug if(debug_channel.announce) D.print(debug_show("Balance is good"));

      let results = Buffer.Buffer<?CastResult>(requests.size());
      let groups = Map.new<Network,  Vector.Vector<(Nat,RemoteNFTPointer)>>();

      let awaitBuffer = Buffer.Buffer<(Nat, CastRequest, async CastResult)>(requests.size());

      var index = 0;
      label proc for(thisItem in requests.vals()){
        debug if(debug_channel.announce) D.print(debug_show("Processing Item: " # debug_show(thisItem)));
        let currentIndex = index;
        index += 1;
        //make sure the user owns the nft
        let #ok(owner) = environment.icrc7.get_token_owner_canonical(thisItem.tokenId) else {
          results.add(?#Err(#NotFound));
          continue proc;
        };

        let ?nft = environment.icrc7.get_nft(thisItem.tokenId) else{
           results.add(?#Err(#NotFound));
           continue proc;
        };

        let defaultUri = "https://" # Principal.toText(canisterId) # ".raw.ic0.app" # "/---/icrc59/-/" # Nat.toText(thisItem.tokenId) # "/metadata?mode=json";


        debug if(debug_channel.announce) D.print(debug_show("NFT: " # debug_show(nft.meta)));

        let uri = switch(nft.meta){
          case(#Map(val)){
            if(Map.size(val) > 0){
              switch(Map.get(val, Map.thash, "icrc97:external_metadata")){
                case(?#Text(val))val;
                case(?#Blob(val)) switch(Text.decodeUtf8(Blob.fromArray(URLEncoding.encode(Blob.toArray(val))))){
                  case(?val) val;
                  case(null) defaultUri;
                };
                case(_){
                  defaultUri
                }
              };
            } else defaultUri;
            
          };
          case(#Text(val)) val;
          case(#Blob(val)) {
            switch(Text.decodeUtf8(Blob.fromArray(URLEncoding.encode(Blob.toArray(val))))){
                case(?val) val;
                case(null) defaultUri;
            };
          };
          case(_) defaultUri
        };
        

        let currentOwner = {owner = caller; subaccount = thisItem.fromSubaccount};

        if(ICRC7.ahash.1(owner, currentOwner) == false){
          results.add(?#Err(#Unauthorized));
          continue proc;
        };

        switch(environment.icrc7.update_token_owner(thisItem.tokenId, ?currentOwner, lockAccount)){
          case(#err(err)){
             results.add(?#Err(#GenericError("Error locking token " # debug_show(err))));
            continue proc;
          };
          case(_){};
        };

        debug if(debug_channel.announce) D.print(debug_show("set lock"));

        let ?originalMinter = BTree.get(state.originalMinterMap, Nat.compare, thisItem.tokenId) else {
          results.add(?#Err(#GenericError("No original minter found")));
          continue proc;
        };

        let castState : CastState = {
          castId = state.nextCastId;
          var remoteCastId = null;
          originalRequest = thisItem;
          nativeChain = state.nativeChain;
          originalMinter = originalMinter;
          uri = uri;
          var includedCycles = balance/requests.size();
          var usedCycles = 0;
          startTime = getTime();
          originalCaller = caller;
          var status = #Created;
          history = Vector.new<(CastStatus, Nat)>();
        };
        state.nextCastId += 1;

        Vector.add(castState.history, (#Created, castState.startTime));

        debug if(debug_channel.announce) D.print(debug_show("Cast State: " # debug_show(castState)));

        ignore BTree.insert(state.castStates, Nat.compare, castState.castId, castState);

        results.add(?#Ok(castState.castId));
        Vector.add(state.pendingCasts, castState.castId);
        procPending := true;
      };

      if(procPending) ignore procPendingCasts();

      return Buffer.toArray(results);
    };

    private func updateCastStatus(castState: CastState, status: CastStatus){
      castState.status := status;
      Vector.add(castState.history, (status, getTime()));
    };

    private func procPendingCasts() : async () {
      let pending = Vector.toArray(state.pendingCasts);
      Vector.clear(state.pendingCasts);
      for(thisCast in pending.vals()){
        ignore procCast(thisCast);
      };
      return;
    };

    private func getTime() : Nat {
      Int.abs(Time.now());
    };

    private func procCast(castId: Nat) : async(){
      debug if(debug_channel.announce) D.print(debug_show("Processing Cast: " # debug_show(castId)));
      let ?castState = BTree.get(state.castStates, Nat.compare, castId) else {
        //todo: Log and handle
        return;
      };

      var bInProgress = false;
      updateCastStatus(castState, #SubmittingToOrchestrator(getTime()));
      let remoteCastID = try{
        let result = await orchestratorService.cast({
          
          castState.originalRequest
          with originalMinterAccount = ?castState.originalMinter;
          uri = castState.uri;
          originalCaller : Service.Account = {
            owner = castState.originalCaller;
            subaccount = castState.originalRequest.fromSubaccount
          };
          nativeContract : OrchestratorService.ContractPointer = castState.nativeChain;
          remoteContract : OrchestratorService.ContractPointer = castState.originalRequest.remoteContract;
          castId = castState.castId;
        } : OrchestratorService.CastRequest);
        switch(result){
          case(#Ok(val)){
            bInProgress := true;
            castState.remoteCastId := ?val;

            updateCastStatus(castState, #SubmittedToOrchestrator({
              remoteCastId = val;
              localCastId = castState.castId;
            }));

          };
          case(#Err(err)){
            debug if(debug_channel.announce) D.print(debug_show("Error in procCast: " # debug_show(err)));
            updateCastStatus(castState, #Error(#GenericError(debug_show(err))));
          };
        };
      } catch (err) {
        debug if(debug_channel.announce) D.print(debug_show("Error in procCast: " # Error.message(err)));
        
        updateCastStatus(castState, #Error(#NetworkError(Error.message(err))));
      } finally {
        //unlock the token
        if(bInProgress == false){
          //rollback
          //todo: Log and handle
          ignore environment.icrc7.update_token_owner(castState.originalRequest.tokenId, ?lockAccount, {owner = caller; subaccount = castState.originalRequest.fromSubaccount});
        };
      };
        
    };

    public func cast_status(caller: Principal, castIds: [Nat]) : async* [?CastStateShared] {

      let results = Buffer.Buffer<?CastStateShared>(castIds.size());
      label proc for(thisCastStatusId in castIds.vals()){
        let ?castState = BTree.get(state.castStates, Nat.compare, thisCastStatusId) else {
          results.add(null);
          continue proc;
        };
        results.add(?MigrationTypes.Current.castStateToShared(castState));
      };
     
     return Buffer.toArray(results);
    };

   
    public func update_cast_status(caller: Principal, castId: Nat, castStatus: CastStatus) : async* Result.Result<(), Text> {

      debug if(debug_channel.announce) D.print(debug_show("Update Cast Status in library: " # debug_show(castId) # " " # debug_show((castStatus, caller, state.orchestrator))));

      if(caller != state.orchestrator){
        debug if(debug_channel.announce) D.print(debug_show("Unauthorized"));
        return #err("Unauthorized");
      };

      let ?castState = BTree.get(state.castStates, Nat.compare, castId) else {
        //todo: Log and handle
        debug if(debug_channel.announce) D.print(debug_show("Cast not found"));
        return #err("Cast not found");
      };

      debug if(debug_channel.announce) D.print(debug_show("Cast State: " # debug_show(castState)));

      switch(castStatus){

        case(#SubmittingToOrchestrator(val)){};
        case(#SubmittedToOrchestrator(val)){};
        case(#WaitingOnContract(val)){};
        case(#WaitingOnMint(val)){};
        case(#WaitingOnTransfer(val)){};
        case(#RemoteFinalized(val)){
          if(networkHash.1(castState.nativeChain.network, castState.originalRequest.remoteContract.network) and Text.equal(Text.toLowercase(castState.nativeChain.contract), Text.toLowercase(castState.originalRequest.remoteContract.contract))){
            //we only burn if the item is being transfered to the network it came from
            await* burnCompletedCast(castId);
          };
        };
        case(#Completed(val)){
          let remoteOwner : RemoteOwner = #remote({
            contract = castState.originalRequest.remoteContract;
            owner = castState.originalRequest.targetOwner;
            timestamp = Int.abs(Time.now());
          });
          ignore BTree.insert(state.remoteOwnerMap, Nat.compare, castState.originalRequest.tokenId, remoteOwner);
        };
        case(#Error(val)){
          debug if(debug_channel.announce) D.print(debug_show("Error handled...trying rollback update_cast_status: " # debug_show(val)));
          let result =  environment.icrc7.update_token_owner(castState.originalRequest.tokenId, ?lockAccount, {owner = castState.originalCaller; subaccount = castState.originalRequest.fromSubaccount});

          debug if(debug_channel.announce) D.print(debug_show("Rollback Result: " # debug_show(result)));

        };
        case(#Created){};
      };

      updateCastStatus(castState, castStatus);

      return #ok(());
    };



    private func burnCompletedCast(castID: Nat) : async* () {
      let ?castState = BTree.get(state.castStates, Nat.compare, castID) else {
        return;
      };

      let burntrx = switch(environment.icrc7.burn_nfts<system>(lockAccount.owner, {created_at_time = ?Nat64.fromNat(getTime());memo = null; tokens = [castState.originalRequest.tokenId]})){
          case(#err(err)){
            //todo: what to do here since the item has been transfered but the burn failed(shouldn't happen but need to handle.  At least it will be stuck in the lock account...study if remint will move it back to the new owner)
            return;
          };
          case(#ok(val)) val;
        };
    };

    public func calcCastCost(items: [CastRequest]) : Nat {
      var total = 0;
      for(thisItem in items.vals()){
        switch(thisItem.remoteContract.network){
          case(#Ethereum(val)){
            total += state.cycleSettings.amountPerETHCast;
          };
          case(#Solana(val)){
            D.trap("nyi");
          };
          case(#Bitcoin(val)){
            D.trap("nyi");
          };
          case(#IC(val)){
            D.trap("nyi");
          };
          case(#Other(val)){
            D.trap("nyi");
          };
        };
      };
      total;
    };
  };
};