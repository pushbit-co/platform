/* global $ */
import Routes from './routes';

const manager = {
  fire: (func, funcname, args) => {
    const namespace = Routes;
    const method = (funcname === undefined) ? 'init' : funcname;
    if (func !== '' && namespace[func] && typeof namespace[func][method] === 'function') {
      namespace[func][method](args);
    }
  },

  loadEvents: () => {
    manager.fire('common');
    manager.fire(document.body.id);
    manager.fire('common', 'finalize');
  }
};

export default manager;
