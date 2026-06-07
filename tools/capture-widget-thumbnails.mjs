#!/usr/bin/env node
import { chromium } from 'playwright';
import fs from 'node:fs/promises';
import path from 'node:path';

const baseUrl = (process.env.GSM_SAFETY_WIDGET_BASE_URL || 'https://obot-claw.github.io/gsm.safety/dev').replace(/\/$/, '');

const widgets = [
  ['ae-explorer', 'AE Explorer', 'examples/Example_AE_Explorer_Workflow.html'],
  ['ae-timelines', 'AE Timelines', 'examples/Example_AE_Timelines_Workflow.html'],
  ['hep-explorer', 'Hep Explorer', 'examples/Example_HepExplorer_Workflow.html'],
  ['paneled-outlier-explorer', 'Paneled Outlier Explorer', 'examples/Example_PaneledOutlierExplorer_Workflow.html'],
  ['safety-delta-delta', 'Safety Delta Delta', 'examples/Example_SafetyDeltaDelta_Workflow.html'],
  ['safety-histogram', 'Safety Histogram', 'examples/Example_SafetyHistogram_Workflow.html'],
  ['safety-outlier-explorer', 'Safety Outlier Explorer', 'examples/Example_SafetyOutlierExplorer_Workflow.html'],
  ['safety-results-over-time', 'Safety Results Over Time', 'examples/Example_SafetyResultsOverTime_Workflow.html'],
  ['safety-shift-plot', 'Safety Shift Plot', 'examples/Example_SafetyShiftPlot_Workflow.html'],
];

const outDir = path.resolve('man/figures/widgets');
await fs.mkdir(outDir, { recursive: true });

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage({ viewport: { width: 1440, height: 1000 }, deviceScaleFactor: 1 });

for (const [slug, label, relativeUrl] of widgets) {
  const url = new URL(relativeUrl, `${baseUrl}/`).toString();
  console.log(`Capturing ${label}: ${url}`);
  const messages = [];
  page.removeAllListeners('console');
  page.on('console', msg => {
    if (['error', 'warning'].includes(msg.type())) messages.push(`${msg.type()}: ${msg.text()}`);
  });

  await page.goto(url, { waitUntil: 'networkidle', timeout: 90000 });
  await page.waitForTimeout(2500);

  const selectors = ['.html-widget', '.html-widget-container', '.widgetframe', 'iframe', 'canvas', 'svg', 'main'];
  let target = null;
  for (const selector of selectors) {
    const locators = await page.locator(selector).all();
    for (const locator of locators.reverse()) {
      const box = await locator.boundingBox().catch(() => null);
      if (box && box.width > 200 && box.height > 150) {
        target = locator;
        break;
      }
    }
    if (target) break;
  }

  const output = path.join(outDir, `${slug}.png`);
  if (target) {
    await target.scrollIntoViewIfNeeded();
    await target.screenshot({ path: output });
  } else {
    await page.screenshot({ path: output, fullPage: false });
  }

  if (messages.length) {
    console.warn(`Console messages for ${label}:`);
    console.warn(messages.slice(0, 8).join('\n'));
  }
}

await browser.close();
