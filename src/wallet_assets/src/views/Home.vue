<template>
  <div class="home">

    <el-row class="row-btn" justify="center">
      <el-button class="login-btn" type="primary" :disabled="param.logedIn" @click="login">LOGIN</el-button>
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
      <el-button class="create-btn" type="primary" :disabled="!param.logedIn" @click="createWallet"
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
import {
  handleAuthenticated,
  getBackendActor,
  getWalletActor
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
      param: {
        principal: undefined,
        logedIn: false,
        walletCreated: false,
        actor: undefined,
        curWallet: undefined,
        curWalletVal: undefined,
        wallets: [],
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
  },
  methods: {
    async initAuth() {
      authClient = await AuthClient.create();
      if (await authClient.isAuthenticated()) {
        handleAuthenticated(authClient);
      }
    },
    async handleLoginSuccess(identity) {
      this.param.logedIn = true;
      this.param.principal = identity;

      this.param.actor = getBackendActor(identity);
      const pricipal = await this.param.actor.whoami();

      // 这里显示自己的 Principal ID
      this.param.membersInit = `{
  "members": [ "${pricipal.toString()}", "2vxsx-fae" ],
  "threshold": 
}`;
    },
    async login() {
      // await this.handleLoginSuccess("anonymous"); // just for test
      await authClient.login({
        onSuccess: async () => {
          const identity = handleAuthenticated(authClient);
          this.handleLoginSuccess(identity);
        },
        identityProvider:
          process.env.DFX_NETWORK === "ic"
            ? "https://identity.ic0.app/#authorize"
            : process.env.LOCAL_II_CANISTER,
        // Maximum authorization expiration is 8 days
        maxTimeToLive: days * hours * nanoseconds,
      });
    },
    async createWallet() {
      const params = JSON.parse(this.param.membersInit);

      const wallet = await this.param.actor.create_manager(params["members"], BigInt(params["threshold"]));
      console.log("Wallet Created:", wallet.toString()); 
      // console.log(`http://127.0.0.1:8000/?canisterId=rno2w-sqaaa-aaaaa-aaacq-cai&id=${wallet.toString()}`);
      const walletActor = getWalletActor(wallet.toString());
      const walletItem = { label: wallet.toString(), value: walletActor };

      this.param.curWallet = wallet.toString();
      this.param.curWalletVal = walletActor;
      this.param.wallets.push(walletItem);

      this.param.walletCreated = true;
    },
    walletChanged(val) {
      this.param.curWalletVal = val;
    },
    async listMembers() {
      const members = await this.param.curWalletVal.get_members();
      this.setResultText(members.map(member => {
        return member.toString();
      }));
    },
    async listCanisters() {
      const canisters = await this.param.curWalletVal.get_canisters();
      this.setResultText(canisters);
    },
    async listProposals() {
      const proposals = await this.param.curWalletVal.view_proposals();
      // console.log("proposals:", proposals);
      this.setResultText(proposals.map(proposal => {
        if (proposal && proposal.length === 0) return undefined;
        
        return {
          proposal_id: Number(BigInt(proposal[0]).toString()),
          operation: Object.keys(proposal[1][0])[0],
          approves: Number(BigInt(proposal[1][1]).toString()),
          status: Object.keys(proposal[1][2])[0],
        };
      }));
    },
    setResultText(message) {
      this.param.result = JSON.stringify(message, null, 2);
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

.create-btn {
  width: 57.64%;
}

.view-proposals-btn {
  width: 57.64%;
}

.members-btn {
  width: 100%;
}

.canisters-btn {
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
