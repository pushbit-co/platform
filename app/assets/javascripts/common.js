import jstz from 'jstz';
import $ from 'jquery';
import {addCSRFField} from './libs/forms';

export default {
  init: () => {
    const timezoneName = jstz.determine().name();
    document.cookie = `timezone=${timezoneName}`;

    $(document).on('submit', 'form', addCSRFField);

    $.extend($.expr[':'], {
      containsi: (elem, i, match) =>
        (elem.textContent || elem.innerText || '').toLowerCase()
        .indexOf((match[3] || '').toLowerCase()) >= 0
    });

    $.fn.serializeObject = () => {
      const o = {};
      const a = this.serializeArray();
      $.each(a, () => {
        if (o[this.name] !== undefined) {
          if (!o[this.name].push) {
            o[this.name] = [o[this.name]];
          }
          o[this.name].push(this.value || '');
        } else {
          o[this.name] = this.value || '';
        }
      });
      return o;
    };
  }
};
