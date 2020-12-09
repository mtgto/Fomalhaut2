import React from "react";
import { Link as RouterLink } from "react-router-dom";

import Card from "@material-ui/core/Card";
import CardContent from "@material-ui/core/CardContent";
import CardMedia from "@material-ui/core/CardMedia";
import Link from "@material-ui/core/Link";
import makeStyles from "@material-ui/core/styles/makeStyles";
import Typography from "@material-ui/core/Typography";

import { Book } from "../domain/book";

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
});

type Props = {
  book: Book;
};

const Cover = (props: Props) => {
  const classes = useStyles();
  return (
    <Link component={RouterLink} to={`/books/${props.book.id}`}>
      <Card variant="outlined" className={classes.card}>
        <CardMedia
          component="img"
          className={classes.media}
          image={`/images/books/${props.book.id}/thumbnail`}
        />
        <CardContent>
          <Typography
            gutterBottom
            variant="caption"
            className={classes.filename}
            component="p"
          >
            {props.book.name}
          </Typography>
        </CardContent>
      </Card>
    </Link>
  );
};
export default Cover;
