<template>
  <div>
    <a-card 
      class="ant-card-shadow" 
      :loading="state.loading" 
      :tab-list="tabList"
      :active-tab-key="key"
      @tabChange="onTabChange"
    >
      <template #title>
        <h3>
          {{state.data.title}}
          <span style="float:right">
            你投资了 {{state.myAmount}} Eth
            <a-button type="primary" v-if="new Date(state.data.endTime * 1000) > new Date() && state.data.success == false" @click="openInvestModal">我要投资</a-button>
            <a-button type="danger" v-if="!state.data.success && state.myAmount != 0" @click="openReturnModal">退钱！</a-button>
          </span>
        </h3>
      </template>
      <a-descriptions bordered v-if="key==='info'">
        <a-descriptions-item label="众筹标题" :span="2">
          {{state.data.title}}
        </a-descriptions-item>
        <a-descriptions-item label="众筹发起人" :span="2">
          {{state.data.initiator}}
        </a-descriptions-item>
        <a-descriptions-item label="开始日期" :span="2">
           {{new Date(state.data.startTime * 1000).toLocaleString()}}
        </a-descriptions-item>
        <a-descriptions-item label="截止日期" :span="2">
           {{new Date(state.data.endTime * 1000).toLocaleString()}}
        </a-descriptions-item>
        <a-descriptions-item label="当前状态">
          <a-tag color="success" v-if="state.data.success === true">
            <template #icon>
              <check-circle-outlined />
            </template>
            众筹成功
          </a-tag>
          <a-tag color="warning" v-else-if="new Date(state.data.endTime * 1000) <= new Date()" >
            <template #icon>
              <close-circle-outlined />
            </template>
            众筹取消
          </a-tag>
           <a-tag color="processing" v-else-if="new Date(state.data.endTime * 1000) > new Date()" >
            <template #icon>
              <sync-outlined :spin="true" />
            </template>
            正在众筹
          </a-tag>
          <a-tag color="error" v-else>
            <template #icon>
              <close-circle-outlined />
            </template>
            众筹失败
          </a-tag>
        </a-descriptions-item>
        <a-descriptions-item label="目标金额">
          <a-statistic :value="state.data.goal">
            <template #suffix>
              Eth
            </template>
          </a-statistic>
        </a-descriptions-item>
        <a-descriptions-item label="当前金额">
          <a-statistic :value="state.data.amount">
            <template #suffix>
              Eth
            </template>
          </a-statistic>
        </a-descriptions-item>
        <a-descriptions-item label="众筹进度">
          <a-progress type="circle" :percent="state.data.success ? 100 : state.data.amount * 100 / state.data.goal" :width="80" />
        </a-descriptions-item>
        <a-descriptions-item label="众筹介绍">
          {{state.data.info}}
        </a-descriptions-item>
      </a-descriptions>

      <Use v-if="key==='use'" :id="id" :data="state.data" :amount="state.myAmount"></Use>

    </a-card>

    <Modal v-model:visible="isInvestOpen">
      <a-card style="width: 600px; margin: 0 2em;" :body-style="{ overflowY: 'auto', maxHeight: '600px' }">
        <template #title><h3 style="text-align: center">投资</h3></template>
        <create-form :model="investModel" :form="investForm" :fields="investFields" />
      </a-card>
    </Modal>

    <Modal v-model:visible="isReturnOpen">
      <a-card style="width: 600px; margin: 0 2em;" :body-style="{ overflowY: 'auto', maxHeight: '600px' }">
        <template #title><h3 style="text-align: center">退款</h3></template>
        <create-form :model="returnModel" :form="returnForm" :fields="returnFields" />
      </a-card>
    </Modal>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, reactive, computed } from 'vue';
import { getOneFunding, Funding, getAccount, getMyFundingAmount, contribute, returnMoney, addListener } from '../api/contract'
import { useRoute } from 'vue-router'
import { message } from 'ant-design-vue';
import { CheckCircleOutlined, SyncOutlined, CloseCircleOutlined } from '@ant-design/icons-vue'
import Modal from '../components/base/modal.vue'
import CreateForm from '../components/base/createForm.vue'
import Use from '../components/Use.vue'
import { Model, Fields, Form } from '../type/form'

const column = [
  {
    dataIndex: ''
  }
]

const tabList = [
  {
    key: 'info',
    tab: '项目介绍',
  },
  {
    key: 'use',
    tab: '使用请求',
  },
];

export default defineComponent({
  name: 'Funding',
  components: { Modal, CreateForm, CheckCircleOutlined, SyncOutlined, CloseCircleOutlined, Use },
  setup() {
    // =========基本数据==========
    const route = useRoute();
    const id = parseInt(route.params.id as string);
    const account = ref('');
    const state = reactive<{data: Funding | {}, loading: boolean, myAmount: number}>({
      data: {},
      loading: true,
      myAmount: 0
    })

    // ===========发起投资表单============
    const isInvestOpen = ref(false);
    const isReturnOpen = ref(false);
    function openInvestModal() { isInvestOpen.value = true }
    function closeInvestModal() { isInvestOpen.value = false }
    function openReturnModal() { isReturnOpen.value = true }
    function closeReturnModal() { isReturnOpen.value = false }

    const investModel = reactive<Model>({
      value: 1
    })
    const investFields = reactive<Fields>({
      value: {
        type: 'number',
        min: 1,
        label: '投资金额'
      }
    })
    const investForm = reactive<Form>({
      submitHint: '投资',
      cancelHint: '取消',
      cancel: () => {
        closeInvestModal();
      },
      finish: async () => {
        try {
          await contribute(id, investModel.value);
          message.success('投资成功')
          fetchData();
          closeInvestModal();
        } catch (e) {
          message.error('投资失败')
        }
      }
    })

    const returnModel = reactive<Model>({
      value: 1
    })
    const returnFields = reactive<Fields>({
      value: {
        type: 'number',
        min: 0.000000000000000001, // 最小单位为1 Wei
        label: '退款金额'
      }
    })
    const returnForm = reactive<Form>({
      submitHint: '退款',
      cancelHint: '取消',
      cancel: () => {
        closeReturnModal();
      },
      finish: async () => {
        try {
          await returnMoney(id, returnModel.value);
          message.success('退款成功');
          fetchData();
          closeReturnModal();
        } catch (e) {
          message.error('退款失败')
        }
      }
    })

    // =========切换标签页===========
    const key = ref('info');
    const onTabChange = (k : 'use' | 'info') => {
      key.value = k;
    }

    // =========加载数据===========
    async function fetchData() {
      state.loading = true;
      try {
        [state.data, state.myAmount] = await Promise.all([getOneFunding(id), getMyFundingAmount(id)]);
        state.loading = false;
        //@ts-ignore
        investFields.value.max = state.data.goal - state.data.amount;
        returnFields.value.max = state.myAmount;
      } catch (e) {
        console.log(e);
        message.error('获取详情失败');
      }
    }

    addListener(fetchData)

    getAccount().then(res => account.value = res)
    fetchData();

    return {
      state, 
      account, 
      isInvestOpen,
      isReturnOpen, 
      openInvestModal,
      openReturnModal, 
      investForm,
      returnForm, 
      investModel,
      returnModel, 
      investFields,
      returnFields, 
      tabList, 
      key, 
      onTabChange, 
      id
    }
  }
});
</script>
