<template>
  <el-dialog title="Operations" v-model="inputParam.operationsDlgVisible" width="30%" center>
    <div class="operations">
      <el-row class="row-bg" justify="center">
        <el-select class="operations" v-model="curOperationVal" filterable placeholder="Choose a Operation"
          @change="operationChanged">
          <el-option v-for="item in operations" :key="item.label" :label="item.label" :value="item.val"></el-option>
        </el-select>
      </el-row>

      <el-row class="row-bg" justify="start" :gutter="24">
        <el-col :offset="0" :span="24">
          <el-form label-position="right" label-width="100px" :model="formLabelAlign">
            <el-form-item label="Parameter 1" v-if="showParamInput1">
              <el-input v-model="formLabelAlign.param1" :placeholder="placeholder1"></el-input>
            </el-form-item>
            <el-form-item label="Parameter 2" v-if="showParamInput2">
              <el-input v-model="formLabelAlign.param2" :placeholder="placeholder2"></el-input>
            </el-form-item>
            <el-form-item label="Add threshold" v-if="showParamInput2Bool">
              <el-switch v-model="addThreshold"></el-switch>
            </el-form-item>
            <el-form-item label="Parameter 2" v-if="showParamInput2Blob">
              <el-input v-model="formLabelAlign.param2" :placeholder="placeholder2" :readonly="true"></el-input>
              <el-upload action="string" :auto-upload="false" :show-file-list="false" :multiple="false"
                :on-change="fileChanged" accept=".wasm">
                <el-button slot="trigger">Select File</el-button>
              </el-upload>
            </el-form-item>
          </el-form>
        </el-col>
      </el-row>

      <el-row class="row-btn" justify="center">
        <el-button class="confirm-btn" type="primary" @click="commit">COMMIT</el-button>
      </el-row>
      <el-row class="row-btn" justify="center">
        <el-button class="cancel-btn" type="primary" @click="cancel">CANCEL</el-button>
      </el-row>
    </div>
  </el-dialog>
</template>

<script>
import {
  ElSelect,
  ElOption,
  ElInput,
  ElRow,
  ElCol,
  ElButton,
  ElDialog,
  ElForm,
  ElFormItem,
  ElSwitch,
  ElUpload,
} from "element-plus";
import "element-plus/es/components/message/style/css";

export default {
  name: "Operations Dialog",
  props: {
    inputParam: {
      type: Object,
      required: true,
    }
  },
  emits: ["operationsDlgClose", "operationsDlgCommit"],
  data() {
    return {
      loadingVote: false,
      curWallet: undefined,
      operations: [
        { label: "Add Member", val: "add_member" },
        { label: "Remove Member", val: "remove_member" },
        { label: "Create Canister", val: "create_canister" },
        { label: "Install Code", val: "install_code" },
        { label: "Start Canister", val: "start_canister" },
        { label: "Stop Canister", val: "stop_canister" },
        { label: "Delete Canister", val: "delete_canister" },
      ],
      curOperationVal: undefined,
      showParamInput1: false,
      showParamInput2: false,
      showParamInput2Bool: false,
      showParamInput2Blob: false,
      addThreshold: false,
      formLabelAlign: {
        param1: "",
        param2: "",
      },
      placeholder1: "",
      placeholder2: "",
      wasmFile: undefined,
    };
  },
  components: {
    ElSelect,
    ElOption,
    ElInput,
    ElRow,
    ElCol,
    ElButton,
    ElDialog,
    ElForm,
    ElFormItem,
    ElSwitch,
    ElUpload,
  },
  methods: {
    operationChanged(val) {
      this.curOperationVal = val;

      this.showParamInput1 = false;
      this.showParamInput2 = false;
      this.showParamInput2Bool = false;
      this.showParamInput2Blob = false;
      this.placeholder1 = "";
      this.placeholder2 = "";
      switch (val) {
        case "add_member":
          this.showParamInput1 = true;
          this.showParamInput2Bool = true;
          this.placeholder1 = "Principal";
          break;
        case "remove_member":
          this.showParamInput1 = true;
          this.placeholder1 = "Principal";
          break;
        case "install_code":
          this.showParamInput1 = true;
          this.showParamInput2Blob = true;
          this.placeholder1 = "Canister ID";
          this.placeholder2 = "Wasm Code File Path";
          break;
        case "start_canister":
        case "stop_canister":
        case "delete_canister":
          this.showParamInput1 = true;
          this.placeholder1 = "Canister ID";
          break;

        default:
      }
    },
    async fileChanged(file) {
      this.formLabelAlign.param2 = file.name;
      this.wasmFile = file;
      // const buf = await file.raw.arrayBuffer();
      // console.log(Buffer.from(buf).toString("hex"));
    },
    commit() {
      const operationsParams = {
        operation: this.curOperationVal,
        param1: this.formLabelAlign.param1,
        param2: this.formLabelAlign.param2,
        addThreshold: this.addThreshold,
        wasmFile: this.wasmFile,
      };
      this.$emit("operationsDlgCommit", operationsParams);
      this.cancel();
    },
    cancel() {
      this.addThreshold = false;
      this.wasmFile = undefined;
      this.formLabelAlign.param1 = "";
      this.formLabelAlign.param2 = "";
      this.$emit("operationsDlgClose", false);
    },
  },
  mounted() {
    this.curWallet = this.canisterId;
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped lang="less">
.operations {
  position: relative;
  left: 0%;
  top: 50%;
  width: 100%;
  margin: 0px 0px 0px 0%;
  border-radius: 5px;
  background: rgba(255, 255, 255, 0.3);
  overflow: hidden;
}

.row-bg {
  padding: 10px 10px;
  background-color: #f9fafc;
}

.row-btn {
  padding: 10px 0px;
  background-color: #f9fafc;
}
</style>
