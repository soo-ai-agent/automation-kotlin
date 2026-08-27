import {useCallback, useEffect} from "react";
import {useServiceErrorHandler} from "@/hooks/use-service-error-handler";
import {useUserDelete} from "./use-user-delete";
import {useUserList} from "./use-user-list";
import {useUserModalRefs} from "./use-user-modal-refs";
import {useUserSelection} from "./use-user-selection";

export function useUsers() {
    const {handleError} = useServiceErrorHandler();
    const {users, isLoading, listState, loadUserList} = useUserList(handleError);
    const {selectedIds, isAllSelected, clearSelectedIds, toggleSelect, toggleSelectAll} = useUserSelection(users);
    const {detailModalRef, openDetail} = useUserModalRefs();

    const reloadUsers = useCallback(async (): Promise<void> => {
        await loadUserList();
        clearSelectedIds();
    }, [loadUserList, clearSelectedIds]);

    const {isDeleting, deleteOne, deleteSelected} = useUserDelete({selectedIds, reloadUsers, handleError});

    useEffect(() => {
        void reloadUsers();
    }, [reloadUsers]);

    return {
        table: {
            users, isLoading, listState, selectedIds, isAllSelected, isDeleting,
            toggleSelect, toggleSelectAll, openDetail, reloadUsers, deleteOne, deleteSelected,
        },
        modalRefs: {detailModalRef},
    };
}
