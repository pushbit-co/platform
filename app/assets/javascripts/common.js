import jstz from 'jstz';
import $ from 'jquery';
import {addCSRFField} from './libs/forms';

export default {
  init: () => {
    const timezoneName = jstz.determine().name();
    document.cookie = `timezone=${timezoneName}`;

    $(document).on('submit', 'form', ev => addCSRFField(ev));
  }
};
