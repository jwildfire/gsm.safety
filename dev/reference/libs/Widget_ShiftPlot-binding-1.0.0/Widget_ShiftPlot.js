HTMLWidgets.widget({
    name: 'Widget_ShiftPlot',
    type: 'output',
    factory: function(el, width, height) {
        let instance = null;
        return {
            renderValue: function(x) {
                if (x.bDebug)
                    console.log(x);

                // Empty R lists serialize as arrays; the module expects an object.
                const settings =
                    x.lSettings && !Array.isArray(x.lSettings) ? x.lSettings : {};

                if (instance && typeof instance.destroy === 'function')
                    instance.destroy();
                el.innerHTML = '';

                instance = SafetyViz.shiftPlot(el, settings);
                instance.init(HTMLWidgets.dataframeToD3(x.dfResults));
            },
            resize: function(width, height) {
                if (instance && typeof instance.resize === 'function')
                    instance.resize();
            }
        };
    }
});
