HTMLWidgets.widget({
    name: 'Widget_TimeToEvent',
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

                // Every declared dataset arrives column-wise under x.lData and
                // becomes an array of records here — the same conversion the
                // single-frame bindings run on x.dfResults.
                const data = {};
                Object.keys(x.lData).forEach(function(name) {
                    data[name] = HTMLWidgets.dataframeToD3(x.lData[name]);
                });

                if (instance && typeof instance.destroy === 'function')
                    instance.destroy();
                el.innerHTML = '';

                instance = SafetyViz.timeToEvent(el, settings);
                instance.init(data);
            },
            resize: function(width, height) {
                if (instance && typeof instance.resize === 'function')
                    instance.resize();
            }
        };
    }
});
