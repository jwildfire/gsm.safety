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

                if (instance && typeof instance.destroy === 'function')
                    instance.destroy();
                el.innerHTML = '';

                instance = SafetyViz.timeToEvent(el, settings);
                // The endpoint is composed from two frames, not pre-derived:
                // the events say who had an event and when, the population is
                // the denominator that censors everyone else.
                instance.init({
                    events: HTMLWidgets.dataframeToD3(x.lData.events),
                    population: HTMLWidgets.dataframeToD3(x.lData.population)
                });
            },
            resize: function(width, height) {
                if (instance && typeof instance.resize === 'function')
                    instance.resize();
            }
        };
    }
});
