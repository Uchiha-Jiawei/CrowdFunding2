<template>
  <div class="home-container">
    <a-card class="funding-card">
      <template #title>
        <div class="card-header">
          <h2 class="title">所有众筹</h2>
          <a-button 
            type="primary" 
            @click="openModal" 
            class="create-btn"
            :style="{
              background: '#1890ff',
              borderRadius: '6px',
              fontSize: '14px',
              height: '36px'
            }"
          >
            <plus-outlined />
            发起众筹
          </a-button>
        </div>
      </template>
      <a-table 
        :columns="columns" 
        :loading="state.loading" 
        :data-source="state.data"
        :pagination="{ 
          pageSize: 10,
          showTotal: total => `共 ${total} 条数据`
        }"
        :row-class-name="(_record, index) => index % 2 === 0 ? 'table-striped' : ''"
      >
        <template #time="{text}">
          <span class="time-text">{{new Date(text * 1000).toLocaleString()}}</span>
        </template>
        <template #tag="{record}">
          <a-tag 
            :class="getTagClass(record)"
            style="padding: 4px 12px; border-radius: 4px;"
          >
            <template #icon>
              <component :is="getTagIcon(record)" />
            </template>
            {{getTagText(record)}}
          </a-tag>
        </template>
        <template #action="{record}">
          <a-button 
            type="link" 
            @click="clickFunding(record.index)"
            class="detail-btn"
          >
            查看详情
          </a-button>
        </template>
      </a-table>
    </a-card>

    <Modal v-model:visible="isOpen">
      <a-card 
        class="modal-card"
        :body-style="{ 
          overflowY: 'auto', 
          maxHeight: '600px',
          padding: '24px'
        }"
      >
        <template #title>
          <div class="modal-header">
            <h2>发起众筹</h2>
          </div>
        </template>
        <create-form 
          :model="model" 
          :form="form" 
          :fields="fields" 
          class="create-form"
        />
      </a-card>
    </Modal>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, reactive } from 'vue';
import Modal from '../components/base/modal.vue'
import CreateForm from '../components/base/createForm.vue'
import { Model, Fields, Form } from '../type/form'
import { contract, getAccount, getAllFundings, Funding, newFunding, addListener } from '../api/contract'
import { message } from 'ant-design-vue'
import { CheckCircleOutlined, SyncOutlined, CloseCircleOutlined, PlusOutlined } from '@ant-design/icons-vue'
import { useRouter } from 'vue-router'


const columns = [
  {
    dataIndex: 'title',
    key: 'title',
    title: '众筹标题'
  },
  {
    title: '目标金额(eth)',
    dataIndex: 'goal',
    key: 'goal',
    sorter: (a: Funding, b: Funding) => (a.goal || 0) - (b.goal || 0)
  },
  {
    title: '目前金额(eth)',
    dataIndex: 'amount',
    key: 'amount',
    sorter: (a: Funding, b: Funding) => (a.amount || 0) - (b.amount || 0)
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
    title: '详情',
    dataIndex: 'action',
    key: 'action',
    slots: { customRender: 'action' }
  }
]

export default defineComponent({
  name: 'Home',
  components: { 
    Modal, 
    CreateForm, 
    CheckCircleOutlined, 
    SyncOutlined, 
    CloseCircleOutlined,
    PlusOutlined
  },
  setup() {
    const isOpen = ref<boolean>(false);
    const state = reactive<{loading: boolean, data: Funding[]}>({
      loading: true,
      data: []
    })

    async function fetchData() {
      state.loading = true;
      try {
        state.data = await getAllFundings();
        state.loading = false;
      } catch (e) {
        // console.log(e);
        message.error('获取众筹失败!');
      }
    }

    async function openModal() { 
      model.account = await getAccount();
      isOpen.value = true;
    }
    function closeModal() { isOpen.value = false; }

    const model = reactive<Model>({
      account: '',
      title: '',
      info: '',
      amount: 0,
      date: null,
    })

    const fields = reactive<Fields>({
      account: {
        type: 'input',
        label: '发起人',
        disabled: true
      },
      title: {
        type: 'input',
        label: '标题',
        rule: {
          required: true,
          trigger: 'blur'
        }
      },
      info: {
        type: 'textarea',
        label: '介绍',
        rule: {
          required: true,
          trigger: 'blur'
        }
      },
      amount: {
        type: 'number',
        label: '金额',
        min: 0
      },
      date: {
        type: 'time',
        label: '截止日期',
      }
    })

    const form = reactive<Form>({
      submitHint: '发起众筹',
      cancelHint: '取消',
      cancel: () => {
        closeModal();
      },
      finish: async () => {
        const seconds = Math.ceil(new Date(model.date).getTime() / 1000);
        try {
          const res = await newFunding(model.account, model.title, model.info, model.amount, seconds);
          console.log(res)
          message.success('发起众筹成功')
          closeModal();
          fetchData();
        } catch(e) {
          console.log(e);
          message.error('发起众筹失败')
        }
      }
    })

    const router = useRouter();
    const clickFunding = (index : number) => {
      router.push(`/funding/${index}`)
    }
    addListener(fetchData)
    fetchData();

    const getTagClass = (record: any) => {
      if (record.success === true) return 'status-tag success'
      if (record.isCancel === true) return 'status-tag warning'
      if (new Date(record.endTime * 1000) > new Date()) return 'status-tag processing'
      return 'status-tag error'
    }

    const getTagIcon = (record: any) => {
      if (record.success === true) return CheckCircleOutlined
      if (record.isCancel === true) return CloseCircleOutlined
      if (new Date(record.endTime * 1000) > new Date()) return SyncOutlined
      return CloseCircleOutlined
    }

    const getTagText = (record: any) => {
      if (record.success === true) return '众筹成功'
      if (record.isCancel === true) return '众筹取消'
      if (new Date(record.endTime * 1000) > new Date()) return '正在众筹'
      return '众筹超时'
    }

    return { 
      openModal, 
      isOpen, 
      model, 
      fields, 
      form, 
      state, 
      columns, 
      clickFunding,
      getTagClass,
      getTagIcon,
      getTagText
    }
  }
});
</script>

<style scoped>
.home-container {
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

.create-btn {
  display: flex;
  align-items: center;
  gap: 8px;
}

.table-striped {
  background-color: #fafafa;
}

.time-text {
  color: #666;
}

.status-tag {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 13px;
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

.detail-btn {
  padding: 0;
  height: auto;
  font-size: 14px;
}

.modal-card {
  width: 600px;
  margin: 0 2em;
  border-radius: 8px;
}

.modal-header {
  text-align: center;
}

.modal-header h2 {
  margin: 0;
  color: #1f1f1f;
  font-size: 20px;
}

.create-form {
  margin-top: 16px;
}

:deep(.ant-form-item) {
  margin-bottom: 24px;
}

:deep(.ant-input),
:deep(.ant-input-number),
:deep(.ant-picker) {
  border-radius: 6px;
}

:deep(.ant-btn) {
  border-radius: 6px;
  height: 36px;
  padding: 0 16px;
}
</style>
