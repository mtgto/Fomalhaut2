import React from "react";
import { useParams } from "react-router-dom";

import Box from "@material-ui/core/Box";
import Container from "@material-ui/core/Container";
import makeStyles from "@material-ui/core/styles/makeStyles";

import { Book } from "../domain/book";
import { Collection } from "../domain/collection";
import Layout from "./layout";

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
    margin: "auto",
  },
});

const pages = (book: Book, classes: ReturnType<typeof useStyles>) => {
  return [...Array(book.pageCount).keys()].map((id: number) => (
    <img
      className={classes.image}
      key={id}
      src={`/assets/books/${book.id}/pages/${id}`}
    ></img>
  ));
};

type Props = {
  collections: Collection[];
  books: Book[];
};

const BookPage = (props: Props) => {
  const { id }: { id: string } = useParams();
  const classes = useStyles();
  const book: Book | undefined = props.books.find((book) => book.id === id);
  return (
    <Layout collections={props.collections}>
      <Container maxWidth="md">
        <Box mx="auto">
          {book ? pages(book, classes) : <span>Loading...</span>}
        </Box>
      </Container>
    </Layout>
  );
};
export default BookPage;
