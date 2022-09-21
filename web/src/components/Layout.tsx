// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import ChevronLeftIcon from "@mui/icons-material/ChevronLeft";
import MenuIcon from "@mui/icons-material/Menu";
import SettingsIcon from "@mui/icons-material/Settings";
import SwipeDownIcon from "@mui/icons-material/SwipeDown";
import SwipeLeftIcon from "@mui/icons-material/SwipeLeft";
import SwipeRightIcon from "@mui/icons-material/SwipeRight";
import AppBar from "@mui/material/AppBar";
import Box from "@mui/material/Box";
import Button from "@mui/material/Button";
import Divider from "@mui/material/Divider";
import IconButton from "@mui/material/IconButton";
import List from "@mui/material/List";
import ListItemButton from "@mui/material/ListItemButton";
import ListItemIcon from "@mui/material/ListItemIcon";
import ListItemText from "@mui/material/ListItemText";
import ListSubheader from "@mui/material/ListSubheader";
import Snackbar from "@mui/material/Snackbar";
import { useTheme } from "@mui/material/styles";
import SwipeableDrawer from "@mui/material/SwipeableDrawer";
import Toolbar from "@mui/material/Toolbar";
import Tooltip from "@mui/material/Tooltip";
import Typography from "@mui/material/Typography";
import {
  Fragment,
  FunctionComponent,
  PropsWithChildren,
  useContext,
  useEffect,
  useState,
} from "react";
import { useLocation, useNavigate } from "rocon/react";
import { message } from "../message";
import { LoadingState, setViewMode, StateContext } from "../reducer";
import { collectionRoutes, filterRoutes } from "./Routes";
// import ListItemLink from "./ListItemLink";

const drawerWidth = 200;

type Props = PropsWithChildren<{
  readonly id?: string; // current id of collection or id of filter
  readonly title?: string;
}>;

const Layout: FunctionComponent<Props> = (props: Props) => {
  const { dispatch, state } = useContext(StateContext);
  const [openLeftDrawer, setOpenLeftDrawer] = useState(false);
  const [openRightDrawer, setOpenRightDrawer] = useState(false);
  const theme = useTheme();
  const location = useLocation();
  const navigate = useNavigate();

  useEffect(() => {
    // close drawer when route changed
    setOpenLeftDrawer(false);
  }, [location]);

  const handleLeftDrawerOpen = () => {
    setOpenLeftDrawer(true);
  };

  const handleLeftDrawerClose = () => {
    setOpenLeftDrawer(false);
  };

  const handleRightDrawerOpen = () => {
    setOpenRightDrawer(true);
  };

  const handleReload = () => {
    document.location.reload();
  };

  return (
    <Fragment>
      <Box flexGrow={1}>
        <AppBar position="static" id="appbar">
          <Toolbar sx={{ justifyContent: "space-between" }}>
            <Box flex={1}>
              <IconButton
                edge="start"
                sx={{ marginRight: theme.spacing(2) }}
                color="inherit"
                aria-label="menu"
                onClick={handleLeftDrawerOpen}
              >
                <MenuIcon />
              </IconButton>
            </Box>
            <Typography variant="h6">{props.title ?? "Fomalhaut2"}</Typography>
            <Box display="flex" flex={1} justifyContent="flex-end">
              <Tooltip title={message.settings}>
                <IconButton
                  size="large"
                  color="inherit"
                  onClick={handleRightDrawerOpen}
                >
                  <SettingsIcon />
                </IconButton>
              </Tooltip>
            </Box>
          </Toolbar>
        </AppBar>
        <SwipeableDrawer
          anchor="left"
          open={openLeftDrawer}
          sx={{
            width: drawerWidth,
            flexShrink: 0,
            ".MuiDrawer-paper": { width: drawerWidth },
          }}
          onOpen={() => setOpenLeftDrawer(true)}
          onClose={() => setOpenLeftDrawer(false)}
        >
          <Box
            display="flex"
            alignItems="center"
            justifyContent="flex-end"
            px={1}
          >
            <IconButton onClick={handleLeftDrawerClose}>
              <ChevronLeftIcon />
            </IconButton>
          </Box>
          <Divider />
          <List
            subheader={
              <ListSubheader disableSticky>{message.library}</ListSubheader>
            }
            dense
          >
            {state.filters.map((filter) => (
              // ListItemLink causes re-render...
              // <ListItemLink
              //   key={filter.id}
              //   primary={filter.name}
              //   route={filterRoutes.route}
              //   match={{ id: filter.id }}
              // />
              <ListItemButton
                key={filter.id}
                selected={filter.id === props.id}
                onClick={() => navigate(filterRoutes.route, { id: filter.id })}
              >
                <ListItemText primary={filter.name} />
              </ListItemButton>
            ))}
          </List>
          <Divider />
          <List
            subheader={
              <ListSubheader disableSticky>{message.collection}</ListSubheader>
            }
            dense
          >
            {state.collections.map((collection) => (
              // <ListItemLink
              //   key={collection.id}
              //   primary={collection.name}
              //   route={collectionRoutes.route}
              //   match={{ id: collection.id }}
              // />
              <ListItemButton
                key={collection.id}
                selected={collection.id === props.id}
                onClick={() =>
                  navigate(collectionRoutes.route, { id: collection.id })
                }
              >
                <ListItemText primary={collection.name} />
              </ListItemButton>
            ))}
          </List>
        </SwipeableDrawer>
        <SwipeableDrawer
          anchor="right"
          open={openRightDrawer}
          onOpen={() => setOpenRightDrawer(true)}
          onClose={() => setOpenRightDrawer(false)}
        >
          <List
            subheader={
              <ListSubheader disableSticky>
                {message.viewMode.name}
              </ListSubheader>
            }
          >
            <ListItemButton
              selected={state.viewMode === "vertical"}
              onClick={() => dispatch(setViewMode("vertical"))}
            >
              <ListItemIcon>
                <SwipeDownIcon />
              </ListItemIcon>
              <ListItemText>{message.viewMode.vertical}</ListItemText>
            </ListItemButton>
            <ListItemButton
              selected={state.viewMode === "left"}
              onClick={() => dispatch(setViewMode("left"))}
            >
              <ListItemIcon>
                <SwipeLeftIcon />
              </ListItemIcon>
              <ListItemText>{message.viewMode.left}</ListItemText>
            </ListItemButton>
            <ListItemButton
              selected={state.viewMode === "right"}
              onClick={() => dispatch(setViewMode("right"))}
            >
              <ListItemIcon>
                <SwipeRightIcon />
              </ListItemIcon>
              <ListItemText>{message.viewMode.right}</ListItemText>
            </ListItemButton>
            <Divider />
          </List>
        </SwipeableDrawer>
        <Snackbar
          open={state.loading === LoadingState.Error}
          message={message.loadError}
          action={
            <Button color="primary" size="small" onClick={handleReload}>
              {message.reload}
            </Button>
          }
        />
      </Box>
      <main>{props.children}</main>
    </Fragment>
  );
};
export default Layout;
