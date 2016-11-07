import jstz from 'jstz';
import $ from 'jquery';
import {addCSRFField} from './libs/forms';

const Common = {
  init: () => {
    const timezoneName = jstz.determine().name();
    document.cookie = `timezone=${timezoneName}`;

    $(document).on('submit', 'form', ev => addCSRFField(ev));
    $(document).on('click', '.alert .close', Common.hideBanner);
  },

  hideBanner: () => {
    $('.alert').fadeOut();
  }
};

export default Common;
