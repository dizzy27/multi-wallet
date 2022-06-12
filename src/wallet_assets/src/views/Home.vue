<template>
  <div class="home">

    <el-row class="row-btn" justify="center">
      <el-button class="login-btn" type="primary" :disabled="param.logedIn" @click="login">{{ loginUser }}</el-button>
    </el-row>

    <el-row class="row-btn" justify="center">
      <el-button
        class="import-btn"
        type="primary"
        :loading="loadingImport"
        :disabled="!param.logedIn || loadingImport"
        @click="openImportWalletBox"
        >IMPORT WALLET</el-button
      >
    </el-row>

    <el-row class="row-bg" justify="center">
      <el-input
        class="members-init"
        v-model="param.membersInit"
        :rows="5"
        type="textarea"
        placeholder="Parameters to Create Multi Wallet"
      />
    </el-row>

    <el-row class="row-btn" justify="center">
      <el-button
        class="create-btn"
        type="primary"
        :loading="loadingCreate"
        :disabled="!param.logedIn || loadingCreate"
        @click="createWallet"
        >CREATE WALLET</el-button
      >
    </el-row>

    <el-row class="row-bg" justify="center">
      <el-select
        class="wallet"
        v-model="param.curWallet"
        filterable
        placeholder="Choose a Multi Wallet"
        :disabled="!param.walletCreated"
        @change="walletChanged"
      >
        <el-option
          v-for="item in param.wallets"
          :key="item.label"
          :label="item.label"
          :value="item.label"
        ></el-option>
      </el-select>
    </el-row>

    <el-row class="row-btn" justify="center">
      <el-button
        class="auth-control-btn"
        type="primary"
        :loading="loadingAuthCtl"
        :disabled="!param.walletCreated || loadingAuthCtl"
        @click="authControl"
        >{{ param.authEnabled ? "DISABLE AUTH" : "ENABLE AUTH" }}</el-button
      >
    </el-row>

    <el-row class="row-btn" justify="start" :gutter="24">
      <el-col :offset="5" :span="7"
        ><el-button class="members-btn" type="primary" :disabled="!param.walletCreated" @click="listMembers"
          >LIST MEMBERS</el-button
        ></el-col
      >
      <el-col :offset="0" :span="7"
        ><el-button class="canisters-btn" type="primary" :disabled="!param.walletCreated" @click="listCanisters"
          >LIST CANISTERS</el-button
        ></el-col
      >
    </el-row>

    <el-row class="row-btn" justify="center">
      <el-button class="view-proposals-btn" type="primary" :disabled="!param.walletCreated" @click="listProposals"
        >VIEW PROPOSALS</el-button
      >
    </el-row>

    <el-row class="row-btn" justify="center">
      <el-button
        class="operations-btn"
        type="primary"
        :loading="loadingOperations"
        :disabled="!param.walletCreated || loadingOperations"
        @click="openOperationsBox"
        >OPERATIONS</el-button
      >
    </el-row>

    <el-row class="row-btn" justify="start" :gutter="24">
      <el-col :offset="5" :span="7"
        ><el-button
          class="approve-btn"
          type="primary"
          :loading="loadingVote"
          :disabled="!param.walletCreated || loadingVote"
          @click="openApproveBox"
          >APPROVE A PROPOSAL</el-button
        ></el-col
      >
      <el-col :offset="0" :span="7"
        ><el-button
        class="reject-btn"
        type="primary"
        :loading="loadingVote"
        :disabled="!param.walletCreated || loadingVote"
        @click="openRejectBox"
          >REJECT A PROPOSAL</el-button
        ></el-col
      >
    </el-row>

    <el-row class="row-bg" justify="center">
      <el-input
        class="result"
        v-model="param.result"
        readonly
        :rows="10"
        type="textarea"
        placeholder="Results to show"
      />
    </el-row>

    <div v-if="operationsParam.operationsDlgVisible">
      <operationsDlg
        :inputParam="operationsParam"
        v-on:operationsDlgClose="handleOperationDlgClose"
        v-on:operationsDlgCommit="handleOperationsDlgCommit"
      ></operationsDlg>
    </div>

  </div>
</template>

<script>
import {
  ElSelect,
  ElOption,
  ElInput,
  ElRow,
  ElCol,
  ElButton,
  ElMessageBox,
  ElMessage,
} from "element-plus";
import "element-plus/es/components/message/style/css";
import operations from "../dialog/operations.vue";
import {
  handleAuthenticated,
  getBackendActor,
  getWalletActor,
  getPrincipalByStr,
  sha256,
} from "../lib";
import { AuthClient } from "@dfinity/auth-client";

const days = BigInt(1);
const hours = BigInt(24);
const nanoseconds = BigInt(3600000000000);

let authClient = undefined;

export default {
  name: "Multi Wallet",
  props: {
    // msg: String
  },
  data() {
    return {
      loginUser: "LOGIN",
      loadingCreate: false,
      loadingImport: false,
      loadingAuthCtl: false,
      loadingOperations: false,
      loadingVote: false,
      operationsParam: {
        operationsDlgVisible: false,
      },
      param: {
        principal: undefined,
        logedIn: false,
        walletCreated: false,
        actor: undefined,
        curWallet: undefined,
        curWalletActor: undefined,
        wallets: [],
        authEnabled: false,
        membersInit: "",
        result: "",
      },
    };
  },
  components: {
    ElSelect,
    ElOption,
    ElInput,
    ElRow,
    ElCol,
    ElButton,
    ElMessageBox,
    ElMessage,
    operationsDlg: operations,
  },
  methods: {
    async initAuth() {
      authClient = await AuthClient.create();
      if (await authClient.isAuthenticated()) {
        handleAuthenticated(authClient);
      }
    },
    handleLoginSuccess(identity) {
      this.param.logedIn = true;
      this.param.principal = identity;

      this.param.actor = getBackendActor(identity);
      const principal = identity.getPrincipal().toString();

      // 这里显示自己的 Principal ID
      this.loginUser = principal;
      this.param.membersInit = `{
  "members": [ "${principal.toString()}", "2vxsx-fae" ],
  "threshold": 
}`;
    },
    async login() {
      // await this.handleLoginSuccess("anonymous"); // just for test
      await authClient.login({
        onSuccess: async () => {
          handleAuthenticated(authClient);
          this.handleLoginSuccess(authClient.getIdentity());
        },
        identityProvider:
          process.env.NODE_ENV === "production" ? 
            "https://identity.ic0.app/#authorize" :
            process.env.LOCAL_II_CANISTER,
        // Maximum authorization expiration is 8 days
        maxTimeToLive: days * hours * nanoseconds,
      });
    },
    async openImportWalletBox() {
      let result;
      const prompt = `Enter the multi-sig wallet canister ID`
      try {
        result = await ElMessageBox.prompt(prompt, "Canister ID", {
          confirmButtonText: "Confirm",
          cancelButtonText: "Cancel",
          // customClass: "canister-id-box",
          inputPattern: /^[0-9a-zA-Z\-]{27}$/,
          inputErrorMessage: "Invalid Canister ID",
        });
      } catch (_) { }
      if (!result) {
        return;
      }

      await this.importWallet(result.value);
    },
    async importWallet(canisterId) {
      const walletActor = getWalletActor(canisterId);
      this.loadingImport = true;
      try {
        this.param.authEnabled = await this.getAuthEnabled(walletActor);
      } catch (err) {
        const error = "Failed to import a multi-sig wallet: \n" + err;
        this.setResultText(error, true);
        this.loadingImport = false;
        return;
      }
      this.loadingImport = false;
      const walletItem = { label: canisterId, value: walletActor };

      this.param.curWallet = canisterId;
      this.param.curWalletActor = walletActor;
      this.param.wallets.push(walletItem);

      this.param.walletCreated = true;
    },
    async createWallet() {
      let params;
      try {
        params = JSON.parse(this.param.membersInit);
      } catch (err) {
        const error = "Failed to parse parameters: \n" + err;
        this.setResultText(error, true);
        return;
      }
      
      this.loadingCreate = true;
      let wallet;
      try {
        wallet = await this.param.actor.create_manager(params["members"], BigInt(params["threshold"]));
        this.setResultText(`Multi-sig wallet Created: ${wallet.toString()}`, true);
        this.param.authEnabled = await this.getAuthEnabled(getWalletActor(wallet.toString()));
      } catch (err) {
        const error = "Failed to create a new multi-sig wallet: \n" + err;
        this.setResultText(error, true);
        this.loadingCreate = false;
        return;
      }
      this.loadingCreate = false;
      
      // console.log(`http://127.0.0.1:8000/?canisterId=rno2w-sqaaa-aaaaa-aaacq-cai&id=${wallet.toString()}`);
      const walletActor = getWalletActor(wallet.toString());
      const walletItem = { label: wallet.toString(), value: walletActor };

      this.param.curWallet = wallet.toString();
      this.param.curWalletActor = walletActor;
      this.param.wallets.push(walletItem);

      this.param.walletCreated = true;
    },
    async getAuthEnabled(walletActor) {
      let enabled = false;
      try {
        enabled = await walletActor.auth_enabled(); 
      } catch (err) {
        const error = "Failed to get auth info of the wallet canister: \n" + err;
        throw new Error(error);
      }
      return enabled;
    },
    walletChanged(val) {
      this.param.curWalletActor = val;
    },
    async authControl() {
      this.loadingAuthCtl = true;
      const walletActor = this.param.curWalletActor;
      try {
        this.param.authEnabled = await this.getAuthEnabled(walletActor);
      } catch (err) {
        const error = "Failed to get auth control of the multi-sig wallet: \n" + err;
        this.setResultText(error, true);
        this.loadingAuthCtl = false;
        return;
      }

      let proposeRes;
      try {
        if (this.param.authEnabled) {
          proposeRes = await walletActor.propose({ disable_auth: null }, []);
        } else {
          proposeRes = await walletActor.propose({ enable_auth: null }, []);
        }
        this.setResultText(`Proposal created with ID: ${proposeRes[0].toString()}`, true);

        this.param.authEnabled = await this.getAuthEnabled(walletActor);
      } catch (err) {
        const error = "Failed to update auth control of the multi-sig wallet: \n" + err;
        this.setResultText(error, true);
      }
      this.loadingAuthCtl = false;
    },
    async listMembers() {
      const members = await this.param.curWalletActor.get_members();
      this.setResultText(members.map(member => {
        return member.toString();
      }));
    },
    async listCanisters() {
      const canisters = await this.param.curWalletActor.get_canisters();
      this.setResultText(canisters);
    },
    async openOperationsBox() {
      this.operationsParam.operationsDlgVisible = true;
    },
    async listProposals() {
      const proposals = await this.param.curWalletActor.view_proposals();
      // console.log("proposals:", proposals);
      this.setResultText(proposals.map(proposal => {
        if (proposal && proposal.length === 0) return undefined;
        
        const op = Object.keys(proposal[1][0])[0];
        let content = {
          "type": op
        };
        switch (op) {
          case "add_member":
            content["principal"] = proposal[1][0][op][0].toString();
            content["add_threshold"] = proposal[1][0][op][1];
            break;
          case "remove_member":
            content["principal"] = proposal[1][0][op].toString();
            break;
          case "install_code":
            content["principal"] = proposal[1][0][op][0].toString();
            content["wasm_hash"] = Buffer.from(proposal[1][0][op][1]).toString("hex");
            break;
          case "start_canister":
          case "stop_canister":
          case "delete_canister":
            content["canister"] = proposal[1][0][op].toString();
            break;

          default:
        }

        return {
          proposal_id: Number(BigInt(proposal[0]).toString()),
          operation: content,
          approves: Number(BigInt(proposal[1][1]).toString()),
          status: Object.keys(proposal[1][2])[0],
        };
      }));
    },
    async openApproveBox() {
      let result;
      const prompt = `Enter ID of the proposal to approve`
      try {
        result = await ElMessageBox.prompt(prompt, "Proposal ID", {
          confirmButtonText: "Confirm",
          cancelButtonText: "Cancel",
          // customClass: "canister-id-box",
          inputPattern: /^[0-9]{1,18}$/,
          inputErrorMessage: "Invalid Proposal ID",
        });
      } catch (_) { }
      if (!result) {
        return;
      }

      this.voteProposal(result.value, true);
    },
    async openRejectBox() {
      let result;
      const prompt = `Enter ID of the proposal to reject`
      try {
        result = await ElMessageBox.prompt(prompt, "Proposal ID", {
          confirmButtonText: "Confirm",
          cancelButtonText: "Cancel",
          // customClass: "canister-id-box",
          inputPattern: /^[0-9]{1,18}$/,
          inputErrorMessage: "Invalid Proposal ID",
        });
      } catch (_) { }
      if (!result) {
        return;
      }

      this.voteProposal(result.value, false);
    },
    handleOperationDlgClose(e) {
      this.operationsParam.operationsDlgVisible = e;
    },
    async handleOperationsDlgCommit(e) {
      // si2b5-pyaaa-aaaaa-aaaja-cai
      // s24we-diaaa-aaaaa-aaaka-cai
      const walletActor = this.param.curWalletActor;
      let op, res;
      this.loadingOperations = true;
      try {
        switch (e.operation) {
          case "add_member":
            op = { "add_member": [getPrincipalByStr(e.param1), e.addThreshold] };
            res = await walletActor.propose(op, []);
            this.setResultText(`Proposal created with ID: ${res[0].toString()}`, true);
            break;

          case "remove_member":
            op = { "remove_member": getPrincipalByStr(e.param1) };
            res = await walletActor.propose(op, []);
            this.setResultText(`Proposal created with ID: ${res[0].toString()}`, true);
            break;

          case "install_code":
            const buf = await e.wasmFile.raw.arrayBuffer();
            if (await this.getAuthEnabled(walletActor)) {
              op = { 
                "install_code": [
                  getPrincipalByStr(e.param1),
                  Array.from(new Uint8Array(sha256([Buffer.from(buf).toString("hex")])))
                ]
              };
              res = await walletActor.propose(op, [Array.from(new Uint8Array(buf))]);
              this.setResultText(`Proposal created with ID: ${res[0].toString()}`, true);
            } else {
              res = await walletActor.install_code(
                Array.from(new Uint8Array(buf)), getPrincipalByStr(e.param1), []);
              this.setResultText(`Operation excuted: ${res.toString()}`, true);
            }
            break;

          case "start_canister":
          case "stop_canister":
          case "delete_canister":
            if (await this.getAuthEnabled(walletActor)) {
              op = {};
              op[e.operation] = getPrincipalByStr(e.param1);
              res = await walletActor.propose(op, []);
              this.setResultText(`Proposal created with ID: ${res[0].toString()}`, true);
            } else {
              if (e.operation === "start_canister") {
                await walletActor.start_canister(getPrincipalByStr(e.param1), []);
              } else if (e.operation === "stop_canister") {
                await walletActor.stop_canister(getPrincipalByStr(e.param1), []);
              } else {
                await walletActor.delete_canister(getPrincipalByStr(e.param1), []);
              }
              this.setResultText(`Operation excuted: ${e.operation}`, true);
            }
            break;

          case "create_canister":
            if (await this.getAuthEnabled(walletActor)) {
              op = { "create_canister": null };
              res = await walletActor.propose(op, []);
              this.setResultText(`Proposal created with ID: ${res[0].toString()} ${res[1].toString()}`, true);
            } else {
              res = await walletActor.create_canister([]);
              this.setResultText(`Operation excuted: ${res.toString()}`, true);
            }
            break;

          default:
            throw new Error("Unsupported operation");
        }
      } catch (err) {
        const error = "Failed to commit operation: \n" + err;
        this.setResultText(error, true);
      }
      this.loadingOperations = false;
      
      // console.log(e.wasmFile)
    },
    async voteProposal(pid, approve) {
      this.loadingVote = true;
      const walletActor = this.param.curWalletActor;
      try {
        const voteRes = await walletActor.vote(BigInt(pid), approve);
        this.setResultText(`Proposal voted with Result: ${voteRes[0]} ${voteRes[1]}`, true);
      } catch (err) {
        const error = "Failed to vote the proposal: \n" + err;
        this.setResultText(error, true);
      }
      this.loadingVote = false;
    },
    setResultText(message, text) {
      this.param.result = text ? message : JSON.stringify(message, null, 2);
    },
  },
  async mounted() {
    await this.initAuth();
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped lang="less">
.row-bg {
  padding: 10px 10px;
  background-color: #f9fafc;
}

.wallet {
  width: 58.32%;
}

.members-init {
  width: 58.32%;
}

.row-btn {
  padding: 10px 0px;
  background-color: #f9fafc;
}

.login-btn {
  width: 57.64%;
}

.import-btn {
  width: 57.64%;
}

.create-btn {
  width: 57.64%;
}

.auth-control-btn {
  width: 57.64%;
}

.view-proposals-btn {
  width: 57.64%;
}

.operations-btn {
  width: 57.64%;
}

.members-btn {
  width: 100%;
}

.canisters-btn {
  width: 100%;
}

.approve-btn {
  width: 100%;
}

.reject-btn {
  width: 100%;
}

.result {
  width: 58.32%;
}
</style>
<style>
.node-box {
  width: 40%;
}
</style>
