// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import React, { useEffect, useContext, useState } from "react";

import Box from "@material-ui/core/Box";
import Container from "@material-ui/core/Container";
import Fab from "@material-ui/core/Fab";
import makeStyles from "@material-ui/core/styles/makeStyles";
import FavoriteIcon from "@material-ui/icons/Favorite";
import FavoriteBorderIcon from "@material-ui/icons/FavoriteBorder";
import KeyboardArrowUpIcon from "@material-ui/icons/KeyboardArrowUp";

import { Book } from "../domain/book";
import { message } from "../message";
import { StateContext, toggleLike } from "../reducer";
import Layout from "./Layout";
import theme from "../theme";

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
    minHeight: "200px",
    display: "block",
    margin: "8px auto",
  },
  fab: {
    marginLeft: theme.spacing(1),
    marginRight: theme.spacing(1),
  },
});

const pages = (book: Book, classes: ReturnType<typeof useStyles>) => {
  return [...Array(book.pageCount).keys()].map((i: number) => (
    <img
      className={classes.image}
      key={i}
      src={`/images/books/${book.id}/pages/${i}`}
    ></img>
  ));
};

const handleClick = () => {
  window.scrollTo({ top: 0, behavior: "smooth" });
};

type Props = {
  readonly id: string;
};
const BookPage: React.VoidFunctionComponent<Props> = (props: Props) => {
  const [calling, setCalling] = useState(false);
  const { state, dispatch } = useContext(StateContext);
  const classes = useStyles();
  const book: Book | undefined = state.books.find(
    (book) => book.id === props.id
  );

  const handleToggleLike = async () => {
    if (book) {
      setCalling(true);
      try {
        await fetch(
          `/api/v1/books/${book.id}/${book.like ? "dislike" : "like"}`,
          { method: "POST" }
        );
        dispatch(toggleLike(book.id));
      } catch (error) {
        console.error(error);
      } finally {
        setCalling(false);
      }
    }
  };

  useEffect(() => {
    if (book) {
      document.title = `${book.name} - Fomalhaut2`;
    }
  }, [book]);

  return (
    <Layout title={book?.name}>
      <Container maxWidth="md">
        <Box mx="auto">
          {book ? pages(book, classes) : <span>{message.loading}</span>}
        </Box>
      </Container>
      <Box display="flex" justifyContent="center" pt={2} pb={8}>
        <Fab
          className={classes.fab}
          aria-label="Toggle Like"
          onClick={handleToggleLike}
          disabled={calling}
        >
          {book?.like ? <FavoriteIcon /> : <FavoriteBorderIcon />}
        </Fab>
        <Fab
          className={classes.fab}
          color="primary"
          aria-label="Go to page top"
          onClick={handleClick}
        >
          <KeyboardArrowUpIcon />
        </Fab>
      </Box>
    </Layout>
  );
};
export default BookPage;
