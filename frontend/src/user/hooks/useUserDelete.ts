import {useCallback, useState} from "react";
import {notify} from "../../common/lib/notify";
import {ConfirmButtonLabel} from "../../common/enums/confirm";
import {deleteUser, deleteUsers} from "../services/userService";
import {DeleteUserOutcome, UserResultMessages} from "../enums/user";
import type {ServiceErrorHandler} from "../../common/hooks/useServiceErrorHandler";

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
        const confirmed: boolean = await notify.confirm({
            title: UserResultMessages.DELETE_CONFIRM, body: "",
            confirmText: ConfirmButtonLabel.DELETE, cancelText: ConfirmButtonLabel.CANCEL,
            destructive: true,
        });
        if (!confirmed) {
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
        const confirmed: boolean = await notify.confirm({
            title: UserResultMessages.BULK_DELETE_CONFIRM, body: "",
            confirmText: ConfirmButtonLabel.DELETE, cancelText: ConfirmButtonLabel.CANCEL,
            destructive: true,
        });
        if (!confirmed) {
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
