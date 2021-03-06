<template>
  <perspective-viewer
    v-if="items"
    ref="perspective-viewer"
  />
</template>
<script>
import perspective from "@finos/perspective";
import "@finos/perspective-viewer";
import "@finos/perspective-viewer-datagrid";
import "@finos/perspective-viewer-d3fc";
import "@finos/perspective-viewer/themes/all-themes.css";

export default {
  name: "Visualizations",
  props: {
    items: {
      type: String,
      default: ''
    },
    typeChart: {
      type: String,
      default: ''
    },
    arrayColumnsQuery: {
      type: Array,
      default: () => []
    },
    objectColumns: {
      type: Object,
      default: () => {}
    },
    config: {
      type: Object,
      default: () => {}
    },
    resetConfigViz: {
      type: Boolean,
      default: false
    }
  },
  watch: {
    items(newValue, oldValue) {
      if (newValue !== oldValue) {
        this.checkIfQueryResultIsEmpty(newValue)
      }
    },
    typeChart(newValue, oldValue) {
      if (newValue !== oldValue) {
        this.viewer.setAttribute('plugin', newValue)
      }
    },
    arrayColumnsQuery(newValue, oldValue) {
      if (JSON.stringify(newValue) !== JSON.stringify(oldValue)) {
        this.viewer.clear()
        this.viewer.update(this.items)
        this.viewer.setAttribute('columns', JSON.stringify(newValue))
      }
    },
    resetConfigViz(newValue) {
      if (newValue) {
        this.clearColumnPivots()
      }
    }
  },
  mounted() {
    this.viewer = this.$refs["perspective-viewer"];
    this.checkIfQueryResultIsEmpty(this.items)
  },
  methods: {
    // You can run a query that gets an empty result, and this isn't an error. But if the result comes empty Perspective has no data to build the table, so console returns an error. We need to check if the result of the query is equal to the columns
    checkIfQueryResultIsEmpty(items) {
      //The result of the query, if returns empty only contains the columns.
      const data = items.trim()
      //Only the columns of the query.
      const arrayColumnsQueryString = this.arrayColumnsQuery.toString()

      if (arrayColumnsQueryString !== data) {
        this.checkPerspectiveTypes()
      } else {
        this.viewer.clear()
        // Well, it's a bit tricky, but reset the table with .clear() only responds when trigger an event, if not trigger an event .clear() isn't fired
        window.dispatchEvent(new Event('resize'))
      }
    },
    checkPerspectiveTypes() {
      //Get columns generates from query
      const arrayColumnsFromQuery = this.arrayColumnsQuery
      //Get columns from API
      const arrayColumnsFromAPI = Object.keys(this.objectColumns)

      /* We compare the columns, if it returns true we pass the schema to Perspective, if false Perspective will convert the columns*/
      const sameColumns = arrayColumnsFromAPI.length === arrayColumnsFromQuery.length && arrayColumnsFromAPI.every(column => arrayColumnsFromQuery.includes(column))

      if (sameColumns) {
        this.initPerspectiveWithSchema(this.items)
      } else {
        this.initPerspective(this.items)
      }
    },
    initPerspectiveWithSchema(data) {
      this.viewer.setAttribute('plugin', this.typeChart)
      this.viewer.clear();

      const transformColumns = this.objectColumns

      Object.keys(transformColumns).forEach((key) => {
        if (transformColumns[key] === 'hstore' || transformColumns[key] === 'jsonb' || transformColumns[key] === 'text') {
          transformColumns[key] = 'string'
        } else if (transformColumns[key] === 'decimal') {
          transformColumns[key] = 'float'
        } else if (transformColumns[key] === 'inet') {
          transformColumns[key] = 'integer'
        }
      });

      let schema = transformColumns

      const loadSchema = this.viewer.worker.table(schema);
      this.viewer.load(loadSchema)
      this.viewer.update(data)

      if (this.config) {
        this.loadConfig()
      }

      this.listenerPerspective()
    },
    initPerspective(data) {
      this.viewer.setAttribute('plugin', this.typeChart)
      this.viewer.clear();

      this.viewer.load(data)

      if (this.config) {
        this.loadConfig()
      }

      this.listenerPerspective()
    },
    loadConfig() {
      this.viewer.restore(this.config);
      //Perspective can't restore row_pivots, column_pivots and computed_columns, so we need to check if visualization config contains some of these values, if contain them we've need to include these values to viewer
      this.loadPivots('column-pivots', this.config.column_pivots)
      this.loadPivots('row-pivots', this.config.row_pivots)
      this.loadPivots('computed-columns', this.config.computed_columns)
    },
    loadPivots(pivot, data) {
      // Check if config contains row_pivots, column_pivots or computed_columns
      if (data) {
        this.viewer.setAttribute(pivot, JSON.stringify(data))
      }
    },
    getConfig() {
      // export the visualization configuration object
      return this.viewer.save()
    },
    toggleConfigPerspective() {
      this.$root.$emit('showSavedVizString', false)
      this.viewer.toggleConfig()
      //Enable save button when user interacts with Perspective columns
      const itemPerspective = document.querySelector('perspective-viewer').shadowRoot
      const rowPerspective = itemPerspective.querySelectorAll("perspective-row");

      rowPerspective.forEach(rowMenu => {
        rowMenu.addEventListener('drag', () => this.$emit("showSaving"))
        rowMenu.addEventListener('click', () => this.$emit("showSaving"))
      });
    },
    listenerPerspective() {
      const shadowRootPerspective = document.querySelector('perspective-viewer').shadowRoot
      const configButtonPerspective = shadowRootPerspective.getElementById('config_button')
      configButtonPerspective.style.display = "none"
      const selectVizPerspective = shadowRootPerspective.getElementById('vis_selector')

      selectVizPerspective.addEventListener('change', () => {
        const selectedValue = selectVizPerspective.options[selectVizPerspective.selectedIndex].value;
        this.$emit("showSaving")
        this.$emit("selectedChart", selectedValue)
      })
    },
    setColumns() {
      this.viewer.setAttribute('columns', this.arrayColumnsQuery)
    },
    clearColumnPivots() {
      /* These properties belong to Perspective's top menu, and we can't clear with this.viewer.clear() or this.viewer.reset(), so, we need it to reset values */
      const attributesTopMenu = ['column-pivots', 'row-pivots', 'computed-columns', 'sort', 'filters']

      for (let index = 0; index < attributesTopMenu.length; index++) {
        this.viewer.setAttribute(attributesTopMenu[index], null)
      }
    }
  }
};
</script>
