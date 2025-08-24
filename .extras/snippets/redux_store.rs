use std::sync::{RwLock, RwLockReadGuard};

#[allow(dead_code)]
pub struct Store<T, U> {
    name:      String,
    state:     RwLock<T>,
    listeners: RwLock<Vec<fn(&T, &U)>>,
    reducer:   fn(&mut T, &U),
}

#[allow(dead_code)]
impl<T, U> Store<T, U> {
    pub fn create_store<S: Into<String>>(name: S, reducer: fn(&mut T, &U), initial_state: T) -> Store<T, U> {
        Store {
            name: name.into(),
            state: RwLock::new(initial_state),
            listeners: RwLock::new(Vec::new()),
            reducer,
        }
    }

    pub fn subscribe(&self, listener: fn(&T, &U)) {
        let mut listeners = self.listeners.write().expect("Could not write subscriber");
        listeners.push(listener);
    }

    pub fn get_state(&self) -> RwLockReadGuard<T> {
        if let Err(_) = self.state.try_read() {
            warn!("Get State Called for `{}`, but would block", self.name);
        }

        self.state.read().expect("Could not get state")
    }

    pub fn dispatch(&self, action: U) {
        (self.reducer)(&mut self.state.write().expect("Could not write state"), &action);

        for listener in &*self.listeners.read().expect("Could not notify listeners") {
            listener(&self.get_state(), &action)
        }
    }
}
