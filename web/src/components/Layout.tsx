// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import React, { forwardRef, useContext, useMemo, useState } from "react";
import { Link as RouterLink, useLocation, useNavigate } from "rocon/react";

import AppBar from "@material-ui/core/AppBar";
import Button from "@material-ui/core/Button";
import Divider from "@material-ui/core/Divider";
import Drawer from "@material-ui/core/Drawer";
import IconButton from "@material-ui/core/IconButton";
import Link from "@material-ui/core/Link";
import List from "@material-ui/core/List";
import ListItem from "@material-ui/core/ListItem";
import ListItemText from "@material-ui/core/ListItemText";
import ListSubheader from "@material-ui/core/ListSubheader";
import Snackbar from "@material-ui/core/Snackbar";
import makeStyles from "@material-ui/core/styles/makeStyles";
import Toolbar from "@material-ui/core/Toolbar";
import Typography from "@material-ui/core/Typography";
import ChevronLeftIcon from "@material-ui/icons/ChevronLeft";
import MenuIcon from "@material-ui/icons/Menu";

import { message } from "../message";
import { LoadingState, StateContext } from "../reducer";
import { collectionRoutes, filterRoutes, topLevelRoutes } from "./Routes";

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
  item: {
    display: "block",
    paddingTop: 0,
    paddingBottom: 0,
  },
  button: {
    textTransform: "none",
    justifyContent: "flex-start",
    width: "100%",
  },
}));

type Props = {
  children: React.ReactNode;
};

const Layout: React.FunctionComponent<Props> = (props: Props) => {
  const state = useContext(StateContext);
  const [open, setOpen] = useState(false);
  const classes = useStyles();
  const location = useLocation();
  const navigate = useNavigate();
  React.useEffect(() => {
    // close drawer when route changed
    setOpen(false);
  }, [location]);

  const handleDrawerOpen = () => {
    setOpen(true);
  };

  const handleDrawerClose = () => {
    setOpen(false);
  };

  const handleReload = () => {
    document.location.reload();
  };

  const RootLink = useMemo(
    () =>
      forwardRef((linkProps, ref) => (
        <RouterLink
          route={topLevelRoutes.exactRoute}
          {...linkProps}
        ></RouterLink>
      )),
    []
  );

  return (
    <>
      <div className={classes.root}>
        <AppBar position="static" id="appbar">
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
              <Link color="inherit" component={RootLink}>
                Fomalhaut2
              </Link>
            </Typography>
            <div className={classes.right} />
          </Toolbar>
        </AppBar>
        <Drawer
          anchor="left"
          open={open}
          className={classes.drawer}
          classes={{
            paper: classes.drawerPaper,
          }}
          onClose={() => setOpen(false)}
        >
          <div className={classes.drawerHeader}>
            <IconButton onClick={handleDrawerClose}>
              <ChevronLeftIcon />
            </IconButton>
          </div>
          <Divider />
          <List subheader={<ListSubheader>{message.library}</ListSubheader>}>
            {state.filters.map((filter) => (
              <ListItem className={classes.item} key={filter.id}>
                <Button
                  className={classes.button}
                  onClick={() =>
                    navigate(filterRoutes.anyRoute, { id: filter.id })
                  }
                >
                  {filter.name}
                </Button>
              </ListItem>
            ))}
          </List>
          <List subheader={<ListSubheader>{message.collection}</ListSubheader>}>
            {state.collections.map((collection) => (
              <ListItem className={classes.item} key={collection.id}>
                <Button
                  className={classes.button}
                  onClick={() =>
                    navigate(collectionRoutes.anyRoute, { id: collection.id })
                  }
                >
                  {collection.name}
                </Button>
              </ListItem>
            ))}
          </List>
        </Drawer>
        <Snackbar
          open={state.loading === LoadingState.Error}
          message={message.loadError}
          action={
            <Button color="primary" size="small" onClick={handleReload}>
              {message.reload}
            </Button>
          }
        />
      </div>
      <main>{props.children}</main>
    </>
  );
};
export default Layout;
