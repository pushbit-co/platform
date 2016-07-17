import jstz from 'jstz';

export default const common = {
  init: () => {
    document.cookie = 'timezone='+jstz.determine().name()+';';

    $(document).on('submit', 'form', function(){
      var $form   = $(this);
      var method = $form.attr('method').toUpperCase();
      var token  = $('meta[name=csrf-token]').attr('content');

      // add the CSRF token as a hidden input to the form
      if (method && method !== 'GET') {
        $form.prepend($('<input>', {name: '_csrf', type: 'hidden', value: token}));
      }
    });

    $.extend($.expr[':'], {
      'containsi': function(elem, i, match, array){
        return (elem.textContent || elem.innerText || '').toLowerCase()
        .indexOf((match[3] || "").toLowerCase()) >= 0;
      }
    });

    $.fn.serializeObject = function(){
      var o = {};
      var a = this.serializeArray();
      $.each(a, function() {
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
}
