HTMLWidgets.widget({
    name: 'Widget_ParticipantProfile',
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

                // The adverse-event domain is the profile's second data frame,
                // and the contract carries it inside the settings rather than
                // as a dataset of its own. Supplying dfAE is what turns the
                // domain on: without settings.ae the module draws labs only.
                if (x.dfAE) {
                    settings.ae = Object.assign(
                        {},
                        !Array.isArray(settings.ae) ? settings.ae : {},
                        { data: HTMLWidgets.dataframeToD3(x.dfAE) }
                    );
                }

                if (instance && typeof instance.destroy === 'function')
                    instance.destroy();
                el.innerHTML = '';

                instance = SafetyViz.participantProfile(
                    el,
                    HTMLWidgets.dataframeToD3(x.dfResults),
                    settings
                );

                // Nothing dispatches participantsSelected in a static report,
                // so the cohort is named here. setSelected() is the same path
                // the event listener takes.
                const ids = Array.isArray(x.chrParticipants)
                    ? x.chrParticipants
                    : x.chrParticipants
                      ? [x.chrParticipants]
                      : [];
                if (ids.length)
                    instance.setSelected(ids);
            },
            resize: function(width, height) {
                if (instance && typeof instance.resize === 'function')
                    instance.resize();
            }
        };
    }
});
