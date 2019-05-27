<template>
  <div>
    <div class="section">
    <div class="container">
      <div class="tags are-medium is-centered">
        <span v-for="v, k in content.regs" :key="k" class="tag" :class="v ? 'is-success': 'is-static'">
          <span class="icon">
            <i :class="'mdi mdi-led-' + (v ? 'on' : 'outline')"></i>
          </span>
          <span>{{k}}</span>
        </span>
      </div>
    </div>
    </div>

    <div class="tile is-ancestor">
      <div class="tile is-parent">
        <div class="tile is-child">
          <Memory
            name="input"
            :buf="content.imem"/>
        </div>
      </div>
      <div class="tile is-parent">
        <div class="tile is-child">
          <Memory
            name="output"
            :buf="content.omem"/>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import Memory from "@/components/Memory.vue";

function isEmpty(obj) {
  for(var key in obj) {
    if(obj.hasOwnProperty(key))
      return false;
  }
  return true;
}

export default {
  name: 'hls_master',
  components: {
    Memory
  },
  props: {
    data: Object
  },
  computed: {
    content() {
      function proc_top (t) {
        return {
          rst:      t[0]==1,
          ap_start: t[1]==1,
          ap_done:  t[2]==1,
          ap_idle:  t[3]==1,
          ap_ready: t[4]==1,
        };
      }
      return (isEmpty(this.data)) ? {
        imem: [],
        omem: [],
        regs: {
          rst:      true,
          ap_start: false,
          ap_done:  false,
          ap_idle:  false,
          ap_ready: false,
        }
      } : {
        imem: this.data.imem,
        omem: this.data.omem,
        regs: proc_top(this.data.top)
      };
    }
  },
  methods: {
    isEmpty(d) {
      return isEmpty(d);
    }
  }
}
</script>
