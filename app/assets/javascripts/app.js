import $ from 'jquery';
import manager from './manager';

// Kick everything off - JS for pages can be found mapped in routes file
$(document).ready(manager.loadEvents);
