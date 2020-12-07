import React, { useEffect, useReducer } from "react";
import { BrowserRouter, Switch, Route } from "react-router-dom";
import { initialState, reducer, setBooks, setCollections } from "../reducer";
import Book from "./book";
import Library from "./library";

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
          <Route path="/">
            <Library collections={state.collections} books={state.books} />
          </Route>
        </Switch>
      </BrowserRouter>
    </>
  );
};
export default App;
