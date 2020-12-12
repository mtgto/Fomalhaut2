import React, { useEffect, useReducer } from "react";
import { BrowserRouter, Route, Switch } from "react-router-dom";

import {
  initialState,
  reducer,
  setBooks,
  setCollections,
  StateContext,
} from "../reducer";
import Book from "./Book";
import Collection from "./Collection";
import Filter from "./Filter";

const App: React.FunctionComponent = () => {
  const [state, dispatch] = useReducer(reducer, initialState);
  useEffect(() => {
    let unmounted = false;
    // Fetch All books
    async function fetchBooks() {
      const books = await fetch("/api/v1/books").then((response) =>
        response.json()
      );
      if (!unmounted) {
        dispatch(setBooks(books));
      }
    }
    async function fetchCollections() {
      const collections = await fetch("/api/v1/collections").then((response) =>
        response.json()
      );
      if (!unmounted) {
        dispatch(setCollections(collections));
      }
    }
    fetchBooks();
    fetchCollections();
    return () => {
      unmounted = true;
    };
  }, []);

  return (
    <StateContext.Provider value={state}>
      <BrowserRouter>
        <Switch>
          <Route path="/books/:id">
            <Book />
          </Route>
          <Route path="/collections/:id">
            <Collection />
          </Route>
          <Route path="/filters/:id">
            <Filter />
          </Route>
          <Route path="/">
            <Filter />
          </Route>
        </Switch>
      </BrowserRouter>
    </StateContext.Provider>
  );
};
export default App;
