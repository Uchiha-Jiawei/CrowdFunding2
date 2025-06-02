<template>
  <div>
    <a-card class="ant-card-shadow">
      <template #title>
        <h3>
          我发起的
        </h3>
      </template>
      <a-table :columns="initColumns" :loading="state.loading" :data-source="state.init">
        <template #time="{text, record}">
          {{new Date(text * 1000).toLocaleString()}}
        </template>
        <template #tag="{text, record}">
          <a-tag color="success" v-if="record.success === true">
            <template #icon>
              <check-circle-outlined />
            </template>
            众筹成功
          </a-tag>
          <a-tag color="processing" v-else-if="new Date(record.endTime * 1000) > new Date()" >
            <template #icon>
              <sync-outlined :spin="true" />
            </template>
            正在众筹
          </a-tag>
          <a-tag color="warning" v-else-if="new Date(record.endTime * 1000) < new Date()">
            <template #icon>
              <close-circle-outlined />
            </template>
            众筹取消
          </a-tag>
          <a-tag color="error" v-else>
            <template #icon>
              <close-circle-outlined />
            </template>
            众筹失败
          </a-tag>
        </template>
        <template #action="{text, record}">
          <a-space>
            <a @click="clickFunding(record.index)">查看详情</a>
            <a-popconfirm
              v-if="new Date(record.endTime * 1000) > new Date() && !record.success"
              title="确定要取消这个众筹项目吗？所有投资者的资金将被退还。"
              @confirm="handleCancel(record.index)"
            >
              <a-button type="link" danger>取消众筹</a-button>
            </a-popconfirm>
          </a-space>
        </template>
      </a-table>
    </a-card>

    <a-card class="ant-card-shadow" style="margin-top: 1em;">
      <template #title>
        <h3>
          我投资的
        </h3>
      </template>
      <a-table :columns="contrColumns" :loading="state.loading" :data-source="state.contr">
        <template #time="{text, record}">
          {{new Date(text * 1000).toLocaleString()}}
        </template>
        <template #tag="{text, record}">
          <a-tag color="success" v-if="record.success === true">
            <template #icon>
              <check-circle-outlined />
            </template>
            众筹成功
          </a-tag>
          <a-tag color="processing" v-else-if="new Date(record.endTime * 1000) > new Date()" >
            <template #icon>
              <sync-outlined :spin="true" />
            </template>
            正在众筹
          </a-tag>
          <a-tag color="warning" v-else-if="new Date(record.endTime * 1000) <= new Date()">
            <template #icon>
              <close-circle-outlined />
            </template>
            众筹取消
          </a-tag>
          <a-tag color="error" v-else>
            <template #icon>
              <close-circle-outlined />
            </template>
            众筹失败
          </a-tag>
        </template>
        <template #action="{text, record}">
          <a-space>
            <a @click="clickFunding(record.index)">查看详情</a>
          </a-space>
        </template>
      </a-table>
    </a-card>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, reactive } from 'vue';
import Modal from '../components/base/modal.vue'
import CreateForm from '../components/base/createForm.vue'
import { Model, Fields, Form } from '../type/form'
import { contract, getAccount, getAllFundings, Funding, newFunding, getMyFundings, addListener, cancelFunding } from '../api/contract'
import { message } from 'ant-design-vue'
import { CheckCircleOutlined, SyncOutlined, CloseCircleOutlined } from '@ant-design/icons-vue'
import { useRouter } from 'vue-router'

const initColumns = [
  {
    dataIndex: 'title',
    key: 'title',
    title: '众筹标题'
  },
  {
    title: '目标金额(eth)',
    dataIndex: 'goal',
    key: 'goal'
  },
  {
    title: '目前金额(eth)',
    dataIndex: 'amount',
    key: 'amount'
  },
  {
    title: '结束时间',
    dataIndex: 'endTime',
    key: 'endTime',
    slots: { customRender: 'time' }
  },
  {
    title: '当前状态',
    dataIndex: 'success',
    key: 'success',
    slots: { customRender: 'tag' }
  },
  {
    title: '操作',
    dataIndex: 'action',
    key: 'action',
    slots: { customRender: 'action' }
  },
]

const contrColumns = [
  {
    dataIndex: 'title',
    key: 'title',
    title: '众筹标题'
  },
  {
    title: '目标金额(eth)',
    dataIndex: 'goal',
    key: 'goal'
  },
  {
    title: '目前金额(eth)',
    dataIndex: 'amount',
    key: 'amount'
  },
  {
    title: '我投资的金额',
    dataIndex: 'myAmount',
    key: 'amount'
  },
  {
    title: '结束时间',
    dataIndex: 'endTime',
    key: 'endTime',
    slots: { customRender: 'time' }
  },
  {
    title: '当前状态',
    dataIndex: 'success',
    key: 'success',
    slots: { customRender: 'tag' }
  },
  {
    title: '详情',
    dataIndex: 'action',
    key: 'action',
    slots: { customRender: 'action' }
  },
]

export default defineComponent({
  name: 'Myself',
  components: { Modal, CreateForm, CheckCircleOutlined, SyncOutlined, CloseCircleOutlined },
  setup() {
    const isOpen = ref<boolean>(false);
    const state = reactive<{loading: boolean, init: Funding[], contr: Funding[]}>({
      loading: true,
      init: [],
      contr: []
    })

    async function fetchData() {
      state.loading = true;
      try {
        const res = await getMyFundings();
        console.log(res)
        state.init = res.init
        state.contr = res.contr
        state.loading = false;
      } catch (e) {
        console.log(e);
        message.error('获取众筹失败!');
      }
    }

    const router = useRouter();
    const clickFunding = (index : number) => {
      router.push(`/funding/${index}`)
    }

    const handleCancel = async (index: number) => {
      try {
        await cancelFunding(index);
        message.success('众筹已取消，资金已退还给投资者');
        fetchData();
      } catch (e) {
        console.log(e);
        message.error('取消众筹失败！');
      }
    }

    addListener(fetchData)
    fetchData();

    return { state, initColumns, contrColumns, clickFunding, handleCancel }
  }
});
</script>
