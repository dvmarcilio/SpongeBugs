{
			Map<File, FolderSnapshot> updated = new LinkedHashMap<>();
			Set<ChangedFiles> changeSet = new LinkedHashSet<>();
			for (FolderSnapshot snapshot : snapshots) {
				FolderSnapshot previous = this.folders.get(snapshot.getFolder());
				updated.put(snapshot.getFolder(), snapshot);
				ChangedFiles changedFiles = previous.getChangedFiles(snapshot,
						this.triggerFilter);
				if (!changedFiles.getFiles().isEmpty()) {
					changeSet.add(changedFiles);
				}
			}
			if (!changeSet.isEmpty()) {
				fireListeners(Collections.unmodifiableSet(changeSet));
			}
			this.folders = updated;
		}