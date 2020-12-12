import React, { useEffect, useReducer } from "react";
import { RoconRoot } from "rocon/react";

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
import Routes from "./Routes";

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
      <RoconRoot>
        <Routes />
      </RoconRoot>
    </StateContext.Provider>
  );
};
export default App;
