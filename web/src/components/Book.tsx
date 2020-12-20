// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import React, { useContext, useEffect } from "react";

import Box from "@material-ui/core/Box";
import Button from "@material-ui/core/Button";
import Container from "@material-ui/core/Container";
import makeStyles from "@material-ui/core/styles/makeStyles";

import { Book } from "../domain/book";
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
  footer: {
    display: "flex",
    justifyContent: "center",
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
          {book ? pages(book, classes) : <span>Loading...</span>}
        </Box>
        <Box mx="auto" mt={2} mb={8} className={classes.footer}>
          <Button color="primary" size="large" onClick={handleClick}>
            Go to page top
          </Button>
        </Box>
      </Container>
    </Layout>
  );
};
export default BookPage;
