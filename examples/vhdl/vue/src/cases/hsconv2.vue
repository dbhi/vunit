<template>
  <div>
    <div class="field has-addons">
      <div class="control has-icons-right">
        <input class="input" type="number" min="0" :max="content.bands-1" v-model="img">
        <span class="icon is-right">
          <i class="mdi mdi-image-filter"></i>
        </span>
      </div>
      <p class="control">
        <a class="button is-static">
          <span>spatial/band</span>
        </a>
      </p>
    </div>

    <div class="level">
      <div class="level-item has-text-centered">
        <img :src="'data:image/png;base64,'+content.imgs.data[img]">
      </div>
      <div class="level-item has-text-centered">
        <img :src="'data:image/png;base64,'+content.imgs.ref[img]">
      </div>
      <div class="level-item has-text-centered">
        <img :src="'data:image/png;base64,'+content.imgs.wrk[img]">
      </div>
      <div class="level-item has-text-centered">
        <img :src="'data:image/png;base64,'+content.imgs.diff[img]">
      </div>
    </div>

    <div class="tile is-ancestor">
      <div class="tile is-parent">
        <div class="tile is-child">
          <Memory
            name="input"
            :buf="content.data"/>
        </div>
      </div>
      <div class="tile is-parent">
        <div class="tile is-child">
          <Memory
            name="output"
            :buf="content.ref"/>
        </div>
      </div>
      <div class="tile is-parent">
        <div class="tile is-child">
          <Memory
            name="output"
            :buf="content.wrk"/>
        </div>
      </div>
      <div class="tile is-parent">
        <div class="tile is-child">
          <Memory
            name="output"
            :buf="content.diff"/>
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
  name: 'hsconv2',
  components: {
    Memory
  },
  props: {
    data: Object
  },
  data() {
    return {
      img: 0,
    }
  },
  computed: {
    content() {
      return (isEmpty(this.data)) ? {
        bands: 1,
        data: [],
        wrk: [],
        imgs: {
          data: [],
          ref: [],
          wrk: [],
          diff: [],
        }
      } : this.data;
    }
  },
  methods: {
    isEmpty(d) {
      return isEmpty(d);
    }
  }
}
</script>
