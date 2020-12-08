import React, { useState } from "react";

import AppBar from "@material-ui/core/AppBar";
import Divider from "@material-ui/core/Divider";
import Drawer from "@material-ui/core/Drawer";
import IconButton from "@material-ui/core/IconButton";
import List from "@material-ui/core/List";
import ListItem from "@material-ui/core/ListItem";
import ListItemIcon from "@material-ui/core/ListItemIcon";
import ListItemText from "@material-ui/core/ListItemText";
import ListSubheader from "@material-ui/core/ListSubheader";
import makeStyles from "@material-ui/core/styles/makeStyles";
import Toolbar from "@material-ui/core/Toolbar";
import Typography from "@material-ui/core/Typography";
import ChevronLeftIcon from "@material-ui/icons/ChevronLeft";
import MenuIcon from "@material-ui/icons/Menu";

import { Collection } from "../domain/collection";
import ListItemLink from "./ListItemLink";

import type { FunctionComponent } from "react";

import type { Theme } from "@material-ui/core/styles/createMuiTheme";
const drawerWidth = 200;
const useStyles = makeStyles((theme: Theme) => ({
  root: {
    flexGrow: 1,
  },
  toolbar: {
    justifyContent: "space-between",
  },
  left: {
    flex: 1,
  },
  right: {
    flex: 1,
    display: "flex",
    justifyContent: "flex-end",
  },
  menuButton: {
    marginRight: theme.spacing(2),
  },
  title: {},
  drawer: {
    width: drawerWidth,
    flexShrink: 0,
  },
  drawerPaper: {
    width: drawerWidth,
  },
  drawerHeader: {
    display: "flex",
    alignItems: "center",
    padding: theme.spacing(0, 1),
    // necessary for content to be below app bar
    ...theme.mixins.toolbar,
    justifyContent: "flex-end",
  },
}));

type Props = {
  collections: Collection[];
  children: React.ReactNode;
};

const Layout: FunctionComponent<Props> = (props: Props) => {
  const [open, setOpen] = useState(false);
  const classes = useStyles();

  const handleDrawerOpen = () => {
    setOpen(true);
  };

  const handleDrawerClose = () => {
    setOpen(false);
  };

  return (
    <>
      <div className={classes.root}>
        <AppBar position="static">
          <Toolbar className={classes.toolbar}>
            <div className={classes.left}>
              <IconButton
                edge="start"
                className={classes.menuButton}
                color="inherit"
                aria-label="menu"
                onClick={handleDrawerOpen}
              >
                <MenuIcon />
              </IconButton>
            </div>
            <Typography variant="h6" className={classes.title}>
              Fomalhaut2
            </Typography>
            <div className={classes.right} />
          </Toolbar>
        </AppBar>
        <Drawer
          variant="persistent"
          anchor="left"
          open={open}
          className={classes.drawer}
          classes={{
            paper: classes.drawerPaper,
          }}
        >
          <div className={classes.drawerHeader}>
            <IconButton onClick={handleDrawerClose}>
              <ChevronLeftIcon />
            </IconButton>
          </div>
          <Divider />
          <List subheader={<ListSubheader>Library</ListSubheader>}>
            <ListItem>
              <ListItemText>All</ListItemText>
            </ListItem>
            <ListItem>
              <ListItemText>Unread</ListItemText>
            </ListItem>
          </List>
          <List subheader={<ListSubheader>Collection</ListSubheader>}>
            {props.collections.map((collection) => (
              <ListItemLink
                to={`/collections/${collection.id}`}
                primary={collection.name}
                key={collection.id}
              />
            ))}
          </List>
        </Drawer>
      </div>
      <main>{props.children}</main>
    </>
  );
};
export default Layout;
