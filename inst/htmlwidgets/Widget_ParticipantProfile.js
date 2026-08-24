HTMLWidgets.widget({
    name: 'Widget_ParticipantProfile',
    type: 'output',
    factory: function(el, width, height) {
        let instance = null;
        return {
            renderValue: function(x) {
                if (x.bDebug)
                    console.log(x);

                const settings =
                    x.lSettings && !Array.isArray(x.lSettings) ? x.lSettings : {};

                // The AE domain is a second frame; it must reach the module as
                // records, not as R's column-wise serialization.
                if (x.dfEvents) {
                    settings.ae = Object.assign({}, settings.ae, {
                        data: HTMLWidgets.dataframeToD3(x.dfEvents)
                    });
                }

                if (instance && typeof instance.destroy === 'function')
                    instance.destroy();
                el.innerHTML = '';

                // NOTE: participantProfile is the only safety.viz factory whose
                // second argument is DATA, not settings.
                instance = SafetyViz.participantProfile(
                    el,
                    HTMLWidgets.dataframeToD3(x.dfResults),
                    settings
                );

                // The standalone mount idles until a participantsSelected event
                // arrives; an R page has no host chart to dispatch one.
                if (x.chrParticipants)
                    instance.setSelected(
                        Array.isArray(x.chrParticipants)
                            ? x.chrParticipants
                            : [x.chrParticipants]
                    );
            },
            resize: function(width, height) {
                if (instance && typeof instance.resize === 'function')
                    instance.resize();
            }
        };
    }
});
