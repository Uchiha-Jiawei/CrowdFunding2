<template>
  <div class="myself-container">
    <a-card class="funding-card">
      <template #title>
        <div class="card-header">
          <h2 class="title">我发起的众筹</h2>
        </div>
      </template>
      <a-table 
        :columns="initColumns" 
        :loading="state.loading" 
        :data-source="state.init"
        :pagination="{ 
          pageSize: 10,
          showTotal: total => `共 ${total} 条数据`
        }"
        :row-class-name="(_record, index) => index % 2 === 0 ? 'table-striped' : ''"
      >
        <template #time="{text}">
          <span class="time-text">
            <calendar-outlined />
            {{new Date(text * 1000).toLocaleString()}}
          </span>
        </template>
        <template #tag="{record}">
          <a-tag :class="getStatusClass(record)">
            <template #icon>
              <component :is="getStatusIcon(record)" />
            </template>
            {{getStatusText(record)}}
          </a-tag>
        </template>
        <template #action="{record}">
          <div class="action-buttons">
            <a-button 
              type="link" 
              @click="clickFunding(record.index)"
              class="detail-btn"
            >
              查看详情
            </a-button>
            <a-popconfirm
              v-if="new Date(record.endTime * 1000) > new Date() && !record.success"
              title="确定要取消这个众筹项目吗？所有投资者的资金将被退还。"
              @confirm="handleCancel(record.index)"
              placement="topRight"
            >
              <a-button 
                type="link" 
                danger
                class="cancel-btn"
              >
                <stop-outlined />
                取消众筹
              </a-button>
            </a-popconfirm>
          </div>
        </template>
      </a-table>
    </a-card>

    <a-card class="funding-card investment-card">
      <template #title>
        <div class="card-header">
          <h2 class="title">我投资的众筹</h2>
        </div>
      </template>
      <a-table 
        :columns="contrColumns" 
        :loading="state.loading" 
        :data-source="state.contr"
        :pagination="{ 
          pageSize: 10,
          showTotal: total => `共 ${total} 条数据`
        }"
        :row-class-name="(_record, index) => index % 2 === 0 ? 'table-striped' : ''"
      >
        <template #time="{text}">
          <span class="time-text">
            <calendar-outlined />
            {{new Date(text * 1000).toLocaleString()}}
          </span>
        </template>
        <template #tag="{record}">
          <a-tag :class="getStatusClass(record)">
            <template #icon>
              <component :is="getStatusIcon(record)" />
            </template>
            {{getStatusText(record)}}
          </a-tag>
        </template>
        <template #action="{record}">
          <a-button 
            type="link" 
            @click="clickFunding(record.index)"
            class="detail-btn"
          >
            <eye-outlined />
            查看详情
          </a-button>
        </template>
        <template #amount="{text}">
          <span class="amount-text">{{text}} ETH</span>
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
import { 
  CheckCircleOutlined, 
  SyncOutlined, 
  CloseCircleOutlined,
  CalendarOutlined,
  StopOutlined,
  EyeOutlined
} from '@ant-design/icons-vue'
import { useRouter } from 'vue-router'

const initColumns = [
  {
    dataIndex: 'title',
    key: 'title',
    title: '众筹标题',
    width: '20%'
  },
  {
    title: '目标金额',
    dataIndex: 'goal',
    key: 'goal',
    sorter: (a: Funding, b: Funding) => (a.goal || 0) - (b.goal || 0),
    slots: { customRender: 'amount' }
  },
  {
    title: '当前金额',
    dataIndex: 'amount',
    key: 'amount',
    sorter: (a: Funding, b: Funding) => (a.amount || 0) - (b.amount || 0),
    slots: { customRender: 'amount' }
  },
  {
    title: '开始时间',
    dataIndex: 'startTime',
    key: 'startTime',
    slots: { customRender: 'time' },
    sorter: (a: Funding, b: Funding) => (a.startTime || 0) - (b.startTime || 0),
    defaultSortOrder: 'descend'
  },
  {
    title: '结束时间',
    dataIndex: 'endTime',
    key: 'endTime',
    slots: { customRender: 'time' },
    sorter: (a: Funding, b: Funding) => (a.endTime || 0) - (b.endTime || 0)
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
    slots: { customRender: 'action' },
    width: '200px'
  },
]

const contrColumns = [
  {
    dataIndex: 'title',
    key: 'title',
    title: '众筹标题',
    width: '20%'
  },
  {
    title: '目标金额',
    dataIndex: 'goal',
    key: 'goal',
    sorter: (a: Funding, b: Funding) => (a.goal || 0) - (b.goal || 0),
    slots: { customRender: 'amount' }
  },
  {
    title: '当前金额',
    dataIndex: 'amount',
    key: 'amount',
    sorter: (a: Funding, b: Funding) => (a.amount || 0) - (b.amount || 0),
    slots: { customRender: 'amount' }
  },
  {
    title: '开始时间',
    dataIndex: 'startTime',
    key: 'startTime',
    slots: { customRender: 'time' },
    sorter: (a: Funding, b: Funding) => (a.startTime || 0) - (b.startTime || 0),
    defaultSortOrder: 'descend'
  },
  {
    title: '我的投资',
    dataIndex: 'myAmount',
    key: 'myAmount',
    sorter: (a: Funding, b: Funding) => ((a.myAmount || 0) - (b.myAmount || 0)),
    slots: { customRender: 'amount' }
  },
  {
    title: '结束时间',
    dataIndex: 'endTime',
    key: 'endTime',
    slots: { customRender: 'time' },
    sorter: (a: Funding, b: Funding) => (a.endTime || 0) - (b.endTime || 0)
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
    slots: { customRender: 'action' },
    width: '120px'
  },
]

export default defineComponent({
  name: 'Myself',
  components: { 
    Modal, 
    CreateForm, 
    CheckCircleOutlined, 
    SyncOutlined, 
    CloseCircleOutlined,
    CalendarOutlined,
    StopOutlined,
    EyeOutlined
  },
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

    const getStatusClass = (record: any) => {
      if (record.success === true) return 'status-tag success'
      if (record.isCancel === true) return 'status-tag warning'
      if (new Date(record.endTime * 1000) > new Date()) return 'status-tag processing'
      return 'status-tag error'
    }

    const getStatusIcon = (record: any) => {
      if (record.success === true) return CheckCircleOutlined
      if (record.isCancel === true) return CloseCircleOutlined
      if (new Date(record.endTime * 1000) > new Date()) return SyncOutlined
      return CloseCircleOutlined
    }

    const getStatusText = (record: any) => {
      if (record.success === true) return '众筹成功'
      if (record.isCancel === true) return '众筹取消'
      if (new Date(record.endTime * 1000) > new Date()) return '正在众筹'
      return '众筹超时'
    }

    addListener(fetchData)
    fetchData();

    return { 
      state, 
      initColumns, 
      contrColumns, 
      clickFunding, 
      handleCancel,
      getStatusClass,
      getStatusIcon,
      getStatusText
    }
  }
});
</script>

<style scoped>
.myself-container {
  padding: 24px;
  background: #f0f2f5;
  min-height: calc(100vh - 64px);
}

.funding-card {
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.03),
              0 1px 6px -1px rgba(0, 0, 0, 0.02),
              0 2px 4px rgba(0, 0, 0, 0.02);
}

.investment-card {
  margin-top: 24px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-header .title {
  margin: 0;
  color: #1f1f1f;
  font-size: 18px;
}

.table-striped {
  background-color: #fafafa;
}

.time-text {
  color: #666;
  display: flex;
  align-items: center;
  gap: 8px;
}

.amount-text {
  color: #1890ff;
  font-weight: 500;
}

.status-tag {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 13px;
  padding: 4px 12px;
  border-radius: 4px;
}

.status-tag.success {
  color: #52c41a;
  background: #f6ffed;
  border-color: #b7eb8f;
}

.status-tag.warning {
  color: #faad14;
  background: #fffbe6;
  border-color: #ffe58f;
}

.status-tag.processing {
  color: #1890ff;
  background: #e6f7ff;
  border-color: #91d5ff;
}

.status-tag.error {
  color: #ff4d4f;
  background: #fff2f0;
  border-color: #ffccc7;
}

.action-buttons {
  display: flex;
  gap: 8px;
}

.detail-btn,
.cancel-btn {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px 0;
  height: auto;
}

:deep(.ant-table-thead > tr > th) {
  background: #fafafa;
  font-weight: 500;
}

:deep(.ant-table-tbody > tr > td) {
  padding: 12px 16px;
}

:deep(.ant-popover-message) {
  min-width: 250px;
}

:deep(.ant-btn-dangerous) {
  color: #ff4d4f;
}

:deep(.ant-btn-dangerous:hover) {
  color: #ff7875;
}

:deep(.ant-table-column-sorter) {
  color: #bfbfbf;
}

:deep(.ant-pagination) {
  margin-top: 16px;
}
</style>
