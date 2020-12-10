import React, { useEffect, useReducer } from "react";
import { BrowserRouter, Route, Switch } from "react-router-dom";

import { initialState, reducer, setBooks, setCollections } from "../reducer";
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
    <>
      <BrowserRouter>
        <Switch>
          <Route path="/books/:id">
            <Book collections={state.collections} books={state.books} />
          </Route>
          <Route path="/collections/:id">
            <Collection
              collections={state.collections}
              filters={state.filters}
            />
          </Route>
          <Route path="/filters/:id">
            <Filter
              collections={state.collections}
              books={state.books}
              filters={state.filters}
            />
          </Route>
          <Route path="/">
            <Filter
              collections={state.collections}
              books={state.books}
              filters={state.filters}
            />
          </Route>
        </Switch>
      </BrowserRouter>
    </>
  );
};
export default App;
