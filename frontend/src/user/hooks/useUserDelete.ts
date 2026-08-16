import {useCallback, useState} from "react";
import {notify} from "../../lib/notify";
import {deleteUser, deleteUsers} from "../services/userService";
import {DeleteUserOutcome, UserResultMessages} from "../enums/user";
import type {ServiceErrorHandler} from "../../hooks/useServiceErrorHandler";

export type UseUserDeleteParams = {
    selectedIds: number[];
    reloadUsers: () => Promise<void>;
    handleError: ServiceErrorHandler;
};

export function useUserDelete({selectedIds, reloadUsers, handleError}: UseUserDeleteParams) {
    const [isDeleting, setIsDeleting] = useState(false);

    const notifyOutcome = useCallback((outcome: DeleteUserOutcome): void => {
        if (outcome === DeleteUserOutcome.ALREADY_MISSING) {
            notify.warning(UserResultMessages.DELETE_ALREADY_MISSING);
            return;
        }
        notify.success(UserResultMessages.DELETE_SUCCESS);
    }, []);

    const deleteOne = useCallback(async (id: number): Promise<void> => {
        if (!notify.confirm(UserResultMessages.DELETE_CONFIRM)) {
            return;
        }
        setIsDeleting(true);
        try {
            const outcome: DeleteUserOutcome = await deleteUser(id);
            notifyOutcome(outcome);
            await reloadUsers();
        } catch (error) {
            handleError(error, UserResultMessages.DELETE_ERROR);
        } finally {
            setIsDeleting(false);
        }
    }, [notifyOutcome, reloadUsers, handleError]);

    const deleteSelected = useCallback(async (): Promise<void> => {
        if (selectedIds.length === 0) {
            notify.warning(UserResultMessages.BULK_DELETE_NO_SELECTION);
            return;
        }
        if (!notify.confirm(UserResultMessages.BULK_DELETE_CONFIRM)) {
            return;
        }
        setIsDeleting(true);
        try {
            const outcome: DeleteUserOutcome = await deleteUsers(selectedIds);
            notifyOutcome(outcome);
            await reloadUsers();
        } catch (error) {
            handleError(error, UserResultMessages.DELETE_ERROR);
        } finally {
            setIsDeleting(false);
        }
    }, [selectedIds, notifyOutcome, reloadUsers, handleError]);

    return {isDeleting, deleteOne, deleteSelected};
}
