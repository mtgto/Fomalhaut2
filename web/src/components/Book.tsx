// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import React, { useContext, useEffect } from "react";

import Box from "@material-ui/core/Box";
import Container from "@material-ui/core/Container";
import Fab from "@material-ui/core/Fab";
import makeStyles from "@material-ui/core/styles/makeStyles";
import KeyboardArrowUpIcon from "@material-ui/icons/KeyboardArrowUp";

import { Book } from "../domain/book";
import { message } from "../message";
import { StateContext } from "../reducer";
import Layout from "./Layout";

const useStyles = makeStyles({
  media: {
    height: 200,
    objectFit: "contain",
  },
  card: {
    //height: "100%",
  },
  filename: {
    display: "-webkit-box",
    WebkitLineClamp: 2,
    WebkitBoxOrient: "vertical",
    overflow: "hidden",
  },
  image: {
    width: "100%",
    maxWidth: "720px",
    display: "block",
    margin: "8px auto",
  },
});

const pages = (book: Book, classes: ReturnType<typeof useStyles>) => {
  return [...Array(book.pageCount).keys()].map((id: number) => (
    <img
      className={classes.image}
      key={id}
      src={`/images/books/${book.id}/pages/${id}`}
    ></img>
  ));
};

type Props = {
  readonly id: string;
};
const BookPage: React.VoidFunctionComponent<Props> = (props: Props) => {
  const state = useContext(StateContext);
  const classes = useStyles();
  const book: Book | undefined = state.books.find(
    (book) => book.id === props.id
  );

  useEffect(() => {
    if (book) {
      document.title = `${book.name} - Fomalhaut2`;
    }
  });

  const handleClick = () => {
    window.scrollTo({ top: 0, behavior: "smooth" });
  };
  return (
    <Layout>
      <Container maxWidth="md">
        <Box mx="auto">
          {book ? pages(book, classes) : <span>{message.loading}</span>}
        </Box>
      </Container>
      <Box display="flex" justifyContent="center" m={2}>
        <Fab color="primary" aria-label="Go to page top" onClick={handleClick}>
          <KeyboardArrowUpIcon />
        </Fab>
      </Box>
    </Layout>
  );
};
export default BookPage;
